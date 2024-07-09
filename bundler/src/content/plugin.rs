use crate::content::Hashable;
use crate::payload::{self};

#[derive(Debug, Default, Clone, PartialEq, Eq, Hash)]
pub struct PluginConfig {
    pub id: String,
    pub packages: Vec<String>,
    pub startup_config: String,
    pub pre_config: String,
    pub post_config: String,
    pub depends: Vec<String>,
    pub on_modules: Vec<String>,
    pub on_events: Vec<String>,
    pub on_userevents: Vec<String>,
    pub on_filetypes: Vec<String>,
    pub on_commands: Vec<String>,
    pub is_opt: bool,
    pub is_denops_client: bool,
}

fn derive_packages(package: Option<String>, packages: Vec<String>) -> Vec<String> {
    let mut pkgs = packages;
    if let Some(p) = package {
        pkgs.push(p);
    }
    pkgs
}

impl Hashable for payload::plugin::EagerComponent {}

impl From<payload::plugin::EagerComponent> for PluginConfig {
    fn from(value: payload::plugin::EagerComponent) -> Self {
        PluginConfig {
            id: value.get_hash(),
            packages: derive_packages(value.package, value.packages),
            startup_config: String::from(value.startup_config),
            is_opt: false,
            ..Default::default()
        }
    }
}

impl Hashable for payload::plugin::LazyComponent {}

impl From<payload::plugin::LazyComponent> for Vec<PluginConfig> {
    fn from(value: payload::plugin::LazyComponent) -> Self {
        let mut configs = vec![];
        let config = PluginConfig {
            id: value.get_hash(),
            packages: derive_packages(value.package, value.packages),
            startup_config: String::from(value.startup_config),
            pre_config: String::from(value.pre_config),
            post_config: String::from(value.post_config),
            depends: vec![], // set values after all dependencies resolved
            on_modules: value.hooks.modules,
            on_events: value.hooks.events,
            on_userevents: value.hooks.user_events,
            on_filetypes: value.hooks.file_types,
            on_commands: value.hooks.commands,
            is_opt: true,
            is_denops_client: value.use_denops,
        };

        let normalized_depends = value
            .depends
            .into_iter()
            .map(|p| match p {
                payload::plugin::lazy::PackageOrComponent::Package(p) => {
                    payload::plugin::lazy::Component::from(p)
                }
                payload::plugin::lazy::PackageOrComponent::Component(c) => c,
            })
            .collect::<Vec<_>>();
        let mut depend_components = normalized_depends
            .into_iter()
            .flat_map(Vec::<PluginConfig>::from)
            .collect::<Vec<_>>();
        let depends = depend_components.iter().map(|c| c.id.clone()).collect();
        configs.push(PluginConfig { depends, ..config });
        configs.append(&mut depend_components);
        configs
    }
}

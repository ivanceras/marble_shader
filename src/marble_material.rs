use bevy::pbr::MaterialExtension;
use bevy::prelude::*;
use bevy::render::render_resource::AsBindGroup;
use bevy::render::render_resource::ShaderRef;
use bevy::render::render_resource::ShaderType;

#[derive(Debug, Default, Clone, Reflect, ShaderType, Resource)]
pub struct MarbleSettings {
    pub scale: f32,
}

#[derive(Asset, AsBindGroup, Reflect, Debug, Clone)]
pub struct MarbleMaterial {
    #[uniform(100)]
    pub settings: MarbleSettings,
}

impl MaterialExtension for MarbleMaterial {

    fn fragment_shader() -> ShaderRef {
        "shaders/marble_material_portable.wgsl".into()
    }
}

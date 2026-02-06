//#![deny(warnings)]
use bevy::color::palettes::basic::*;
use bevy::math::*;
use bevy::pbr::wireframe::WireframeConfig;
use bevy::prelude::*;
use bevy_trackball::prelude::*;
use bevy::pbr::ExtendedMaterial;

use marble_material::*;

mod marble_material;

fn main() {
    App::new()
        .add_plugins(DefaultPlugins)
        .add_systems(Startup, setup)
        .add_plugins(TrackballPlugin)
        .add_plugins(MaterialPlugin::<
            ExtendedMaterial<StandardMaterial, MarbleMaterial>,
        >::default())
        .insert_resource(WireframeConfig {
            global: false,
            default_color: Color::WHITE,
        })
        .run();
}

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
    mut marble_materials: ResMut<Assets<ExtendedMaterial<StandardMaterial, MarbleMaterial>>>,
) {

    let marble_material = marble_materials.add(ExtendedMaterial {
        base: StandardMaterial::default(),
        extension: MarbleMaterial {
            settings: MarbleSettings::default(),
        },
    });

    let target = Vec3::ZERO;
    let eye = Vec3::Z * 20.0 + target;
    let up = Vec3::Y;
    commands.spawn((
        Camera3d::default(),
        Camera {
            order: 0,
            is_active: true,
            ..default()
        },
        TrackballController::default(),
        TrackballCamera::look_at(target, eye, up),
        Projection::Perspective(PerspectiveProjection {
            near: 0.000001,
            ..default()
        }),
        AmbientLight {
            color: Color::WHITE,
            brightness: 100.0,
            ..default()
        },
    ));

    commands.spawn((
        DirectionalLight {
            shadows_enabled: true,
            illuminance: 10_000.0,
            ..default()
        },
        Transform {
            rotation: Quat::from_rotation_x(-45f32.to_radians())
                * Quat::from_rotation_y(45f32.to_radians()),
            ..default()
        },
    ));

    commands.spawn((
        Mesh3d(meshes.add(Cuboid::new(10.0, 10.0, 10.0))),
        MeshMaterial3d(marble_material),
        Transform { ..default() },
    ));
}

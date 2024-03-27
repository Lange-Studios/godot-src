use godot::prelude::*;
use godot::engine::Label;

struct RustExtension;

#[gdextension]
unsafe impl ExtensionLibrary for RustExtension {}

#[derive(GodotClass)]
#[class(init, base=Node)]
pub struct HelloWorld {
    pub base: Base<Node>,
}

#[godot_api]
impl INode for HelloWorld {
    fn ready(&mut self) {
        self.base().get_parent().unwrap().cast::<Label>().set_text("Hello from rust! :)".into());
    }
}

#[godot_api]
impl HelloWorld {}

using Godot;
using System;

public partial class Hello : Label
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		Text = "Hello from C#! :)";
	}
}

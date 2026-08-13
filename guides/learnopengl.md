# LearnOpenGL examples

EAGL ports the [Learn OpenGL](https://learnopengl.com) Getting Started series and the start of the Lighting chapter so C++ tutorials can be followed in Elixir.

Helpers take atoms (`create_shader(:vertex, …)`). Direct OpenGL still uses `:gl` and `@gl_*` constants from `use EAGL.Const`.

Clone the repository (examples are not in the Hex package) and run:

```
mix examples
```

## Menu

```
0. Non-Learn OpenGL Examples:
  01) Math Example - Comprehensive EAGL.Math functionality demo
  02) Teapot Example - 3D teapot with Phong shading

1. Learn OpenGL Getting Started Examples:

  Hello Window:     111) 1.1 Window    112) 1.2 Clear Colors

  Hello Triangle:   121) 2.1 Triangle  122) 2.2 Indexed    123) 2.3 Exercise1
                    124) 2.4 Exercise2 125) 2.5 Exercise3

  Shaders:          131) 3.1 Uniform   132) 3.2 Interpolation 133) 3.3 Class
                    134) 3.4 Exercise1 135) 3.5 Exercise2     136) 3.6 Exercise3

  Textures:         141) 4.1 Basic     142) 4.2 Combined      143) 4.3 Exercise1
                    144) 4.4 Exercise2 145) 4.5 Exercise3     146) 4.6 Exercise4

  Transformations:  151) 5.1 Basic     152) 5.2 Exercise1  153) 5.2 Exercise2

  Coordinate Systems: 161) 6.1 Basic   162) 6.2 Depth     163) 6.3 Multiple
                      164) 6.4 Exercise

  Camera:           171) 7.1 Circle    172) 7.2 Keyboard+DT 173) 7.3 Mouse+Zoom
                    174) 7.4 Camera Class 175) 7.5 Exercise1 (FPS) 176) 7.6 Exercise2 (Custom LookAt)

2. Learn OpenGL Lighting Examples:

  Colors:           211) 1.1 Colors
  Basic Lighting:   212) 2.1 Diffuse   213) 2.2 Specular

3. GLTF Examples:

  311) Box              312) Box Textured    313) Duck
  314) Box Animated     315) Damaged Helmet
```

Enter a code, `q` to quit, or `r` to refresh.

## FPS camera

LearnOpenGL examples 7.4–7.6 and the lighting chapter use a first-person WASD camera in `examples/learnopengl/camera.ex` (`EAGL.Examples.LearnOpenGL.Camera`). That module is tutorial code, not part of the library API. Applications that inspect models should use `EAGL.OrbitCamera`.

## Automated tests

Examples accept `timeout:` so CI can run them without interaction:

```elixir
MyExample.run_example(timeout: 500)
```

See `test/examples_test.exs` and `test/README.md`.

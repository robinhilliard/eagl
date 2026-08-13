# glTF / GLB in EAGL

EAGL splits glTF into three layers:

1. **`GLTF.*` parser** — spec structs and GLB loading. No OpenGL, no `EAGL.Const`.
2. **`GLTF.EAGL` bridge** — converts primitives to `EAGL.Mesh`, nodes to `EAGL.Node`, scenes to `EAGL.Scene`.
3. **`EAGL.Scene`** — hierarchical render, orbit camera, animation playback.

Skinning is parsed (`GLTF.Skin`) but not yet applied at draw time.

## Load and render

```elixir
{:ok, program} = GLTF.EAGL.create_pbr_shader()
{:ok, scene, gltf, data_store} = GLTF.EAGL.load_scene("model.glb", program)
{:ok, textures} = GLTF.EAGL.load_textures(gltf, data_store)

orbit = EAGL.OrbitCamera.fit_to_scene(scene)
view = EAGL.OrbitCamera.get_view_matrix(orbit)
proj = EAGL.OrbitCamera.get_projection_matrix(orbit, aspect)

GLTF.EAGL.set_pbr_uniforms(program, textures: textures, view_pos: EAGL.OrbitCamera.get_position(orbit))
EAGL.Scene.render(scene, view, proj)
```

Lower-level entry points: `GLTF.EAGL.load_glb/2`, `GLTF.EAGL.to_scene/3`, `GLTF.EAGL.primitive_to_vao/5`.

## Sample files

GLTF examples need Khronos sample GLBs (not in the repo):

```bash
mix glb.samples
```

Progressive examples live in `examples/gltf/` (box → textured → duck → animated box → Damaged Helmet).

## Parser modules

All glTF 2.0 document properties are Elixir structs: `GLTF`, `GLTF.Asset`, `GLTF.Scene`, `GLTF.Node`, `GLTF.Mesh`, `GLTF.Accessor`, `GLTF.Buffer`, `GLTF.BufferView`, `GLTF.Material`, `GLTF.Texture`, `GLTF.Sampler`, `GLTF.Image`, `GLTF.Animation`, `GLTF.Skin`, `GLTF.Camera`.

Component types and sampler filters are stored as glTF spec integers (5126, 9729, …), which happen to equal the OpenGL constants. Conversion to EAGL draw state happens only in `GLTF.EAGL`.

## HTTP client on macOS

Erlang `:httpc` can fail HTTPS on some macOS builds (`http_util.timestamp/0`). EAGL already depends on `:req`. Pass `http_client: :req` when loading from URLs:

```elixir
{:ok, glb} = GLTF.GLBLoader.parse_url(url, http_client: :req)
```

## Not yet

- Multi-primitive meshes (bridge uses primitive 0)
- GPU skinning / joint matrices
- glTF JSON export
- Strided buffer views for interleaved GPU upload

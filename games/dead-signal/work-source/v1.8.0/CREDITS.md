# Graphics sources and licensing

Dead Signal's game code, layout, garment meshes, weapon/transport detail, asset
processing and integration are project work. Some base meshes and materials
are adapted from the sources below. They are not presented as original Dead
Signal source meshes or as assets from Call of Duty / Black Ops.

| Source | Used for | License and source |
| --- | --- | --- |
| MakeHuman Community | Anatomical base, default skeleton and vertex weights; posed and cut into rigid game bone shells | CC0; [base source](https://github.com/makehumancommunity/makehuman/tree/master/makehuman/data), [exported asset license](https://static.makehumancommunity.org/makehuman/faq/can_i_sell_models_created_with_makehuman.html) |
| NewDLC, OpenGameArt | Rigged wolf geometry, adapted for the infected hound | CC0; [3D Wolf](https://opengameart.org/content/3d-wolf) |
| Poly Haven contributors | Service pistol, bolt-action rifle, generator, office desk, storage/tool carts, covered car, radio transceiver, industrial lamps, military crate, barrel and cabinet | CC0; [license](https://polyhaven.com/license); individual source URLs in `source-manifest.json` |
| Poly Haven contributors | Concrete/floor/plaster/brick/steel/rust/canvas/leather/rubber/wood/snow PBR source maps | CC0; individual asset URLs and source hashes in `source-manifest.json` |
| Papyszoo CC0 Public Domain Models repository | Distribution mirror used to obtain the Poly Haven GLB files | [mirror](https://github.com/Papyszoo/CC0-Public-Domain-Models); original Poly Haven source and license retained |
| Original built-in image generation | Infected skin, coarse canine fur and neutral uniform base colors | Exact prompts and project paths in `generated-manifest.json`; original PNGs retained in `Original/` |

The project-generated fur/albedo is applied to the hound rather than the
source's stylized coat color. The source canine normal map is retained. Uniform
albedo is original generated neutral twill; cloth normals/roughness are adapted
from the credited material source. Color-map compression and rigid bone cuts
are asset processing steps, not evidence of Roblox engine rendering.

The texture source filenames, download locations and SHA-256 hashes are recorded
in `source-manifest.json`. `bindings.json` and `validation.json` describe the
shipped GLB, including its current hash. Generated map loading key art is
documented separately in `Assets/Loading/art-manifest.json`.

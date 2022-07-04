# fontstash-zig
[Fontstash](https://github.com/memononen/fontstash/) bindings for [Zig](https://ziglang.org/)!

Font stash is light-weight online font texture atlas builder. This version uses FreeType for high-quality glyph generation (see [build-freetype.zig](example/build-freetype.zig) for the FreeType build script).

The code is split in two parts, the font atlas and glyph quad generator [fontstash.zig](fontstash.zig), and a sample OpenGL 3 backend [glfontstash.zig](glfontstash.zig).

## Example

See [example.zig](example/example.zig) for a complete example.

The example pulls in several other dependencies (glfw, zgl, freetype) in order to get a working OpenGL window, but they can be ignored if you just want to see Fontstash API usage.


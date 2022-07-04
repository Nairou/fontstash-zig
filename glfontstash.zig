const std = @import("std");
const fons = @import("fontstash.zig");
const gl = @import("example/deps/zgl/zgl.zig");

pub const GlState = struct {
    texture: gl.Texture = gl.Texture.invalid,
    vertexArray: gl.VertexArray = gl.VertexArray.invalid,
    vertexBuffer: gl.Buffer = gl.Buffer.invalid,
    tcoordBuffer: gl.Buffer = gl.Buffer.invalid,
    colorBuffer: gl.Buffer = gl.Buffer.invalid,
    width: usize = 0,
    height: usize = 0,
};

pub const ZeroPosition = enum(c_int) {
    TopLeft = 1,
    BottomLeft = 2,
};

pub fn create( state: *GlState, width: u32, height: u32, zero: ZeroPosition ) !fons.Context {
    var params = fons.Params {
        .width = @intCast(c_int, width),
        .height = @intCast(c_int, height),
        .flags = @intCast(u8, @enumToInt(zero)),
        .renderCreate = fonsRenderCreate,
        .renderResize = fonsRenderResize,
        .renderUpdate = fonsRenderUpdate,
        .renderDraw = fonsRenderDraw,
        .renderDelete = fonsRenderDelete,
        .userPtr = state,
    };
    return try fons.createInternal(&params);
}

pub fn delete( context: *fons.Context ) void {
    fons.deleteInternal( &context.context );
}

pub fn color2int( r: u8, g: u8, b: u8, a: u8 ) u32 {
    return (@intCast(u32, r)) | (@intCast(u32, g) << 8) | (@intCast(u32, b) << 16) | (@intCast(u32, a) << 24);
}

fn fonsRenderCreate( userPtr: ?*anyopaque, width: c_int, height: c_int) callconv(.C) c_int {
    const state = @ptrCast(*GlState, @alignCast(@alignOf(*GlState), userPtr.?));
    if (state.texture != gl.Texture.invalid) {
        gl.deleteTexture(state.texture);
        state.texture = gl.Texture.invalid;
    }

    state.texture = gl.genTexture();
    if (state.texture == gl.Texture.invalid) {
        return 0;
    }

    if (state.vertexArray == gl.VertexArray.invalid) {
        state.vertexArray = gl.genVertexArray();
    }
    if (state.vertexArray == gl.VertexArray.invalid) {
        return 0;
    }

    if (state.vertexBuffer == gl.Buffer.invalid) {
        state.vertexBuffer = gl.genBuffer();
    }
    if (state.vertexBuffer == gl.Buffer.invalid) {
        return 0;
    }

    if (state.tcoordBuffer == gl.Buffer.invalid) {
        state.tcoordBuffer = gl.genBuffer();
    }
    if (state.tcoordBuffer == gl.Buffer.invalid) {
        return 0;
    }

    if (state.colorBuffer == gl.Buffer.invalid) {
        state.colorBuffer = gl.genBuffer();
    }
    if (state.colorBuffer == gl.Buffer.invalid) {
        return 0;
    }

    state.width = @intCast(usize, width);
    state.height = @intCast(usize, height);
    state.texture.bind(gl.TextureTarget.@"2d");
    gl.textureImage2D(gl.TextureTarget.@"2d", 0, gl.PixelFormat.red, state.width, state.height, gl.PixelFormat.red, gl.PixelType.unsigned_byte, null);
    gl.texParameter( gl.TextureTarget.@"2d", gl.TextureParameter.min_filter, gl.TextureParameterType(gl.TextureParameter.min_filter).linear);
    gl.texParameter( gl.TextureTarget.@"2d", gl.TextureParameter.mag_filter, gl.TextureParameterType(gl.TextureParameter.mag_filter).linear);
    gl.texParameter( gl.TextureTarget.@"2d", gl.TextureParameter.swizzle_r, gl.TextureParameterType(gl.TextureParameter.swizzle_r).one);
    gl.texParameter( gl.TextureTarget.@"2d", gl.TextureParameter.swizzle_g, gl.TextureParameterType(gl.TextureParameter.swizzle_g).one);
    gl.texParameter( gl.TextureTarget.@"2d", gl.TextureParameter.swizzle_b, gl.TextureParameterType(gl.TextureParameter.swizzle_b).one);
    gl.texParameter( gl.TextureTarget.@"2d", gl.TextureParameter.swizzle_a, gl.TextureParameterType(gl.TextureParameter.swizzle_a).red);
    return 1;
}

fn fonsRenderResize( userPtr: ?*anyopaque, width: c_int, height: c_int) callconv(.C) c_int {
    return fonsRenderCreate(userPtr, width, height);
}

fn fonsRenderUpdate( userPtr: ?*anyopaque, rect: [*c]c_int, data: [*c]const u8) callconv(.C) void {
    const state = @ptrCast(*GlState, @alignCast(@alignOf(*GlState), userPtr.?));
    var w = rect[2] - rect[0];
    var h = rect[3] - rect[1];

    if (state.texture == gl.Texture.invalid) {
        return;
    }

    var alignment = gl.getInteger(gl.Parameter.unpack_alignment);
    var rowLength = gl.getInteger(gl.Parameter.unpack_row_length);
    var skipPixels = gl.getInteger(gl.Parameter.unpack_skip_pixels);
    var skipRows = gl.getInteger(gl.Parameter.unpack_skip_rows);

    state.texture.bind(gl.TextureTarget.@"2d");
    gl.pixelStore(gl.PixelStoreParameter.unpack_alignment, 1);
    gl.pixelStore(gl.PixelStoreParameter.unpack_row_length, @intCast(usize, state.width));
    gl.pixelStore(gl.PixelStoreParameter.unpack_skip_pixels, @intCast(usize, rect[0]));
    gl.pixelStore(gl.PixelStoreParameter.unpack_skip_rows, @intCast(usize, rect[1]));

    gl.texSubImage2D( gl.TextureTarget.@"2d", 0, @intCast(usize, rect[0]), @intCast(usize, rect[1]), @intCast(usize, w), @intCast(usize, h), gl.PixelFormat.red, gl.PixelType.unsigned_byte, data);

    gl.pixelStore(gl.PixelStoreParameter.unpack_alignment, @intCast(usize, alignment));
    gl.pixelStore(gl.PixelStoreParameter.unpack_row_length, @intCast(usize, rowLength));
    gl.pixelStore(gl.PixelStoreParameter.unpack_skip_pixels, @intCast(usize, skipPixels));
    gl.pixelStore(gl.PixelStoreParameter.unpack_skip_rows, @intCast(usize, skipRows));
}

fn fonsRenderDraw( userPtr: ?*anyopaque, verts: [*c]const f32, tcoords: [*c]const f32, colors: [*c]const c_uint, nverts: c_int) callconv(.C) void {
    const state = @ptrCast(*GlState, @alignCast(@alignOf(*GlState), userPtr.?));
    if (state.texture == gl.Texture.invalid or state.vertexArray == gl.VertexArray.invalid) {
        return;
    }

    gl.activeTexture(gl.TextureUnit.texture_0);
    state.texture.bind(gl.TextureTarget.@"2d");

    state.vertexArray.bind();

    const fonsVertexAttrib = 0;
    gl.enableVertexAttribArray(fonsVertexAttrib);
    state.vertexBuffer.bind(gl.BufferTarget.array_buffer);
    const VertFormat = packed struct {
        x: f32,
        y: f32,
    };
    gl.bufferData(gl.BufferTarget.array_buffer, VertFormat, @ptrCast([*]const VertFormat, verts)[0..@intCast(usize, nverts)], gl.BufferUsage.dynamic_draw);
    gl.vertexAttribPointer(fonsVertexAttrib, 2, gl.Type.float, false, 0, 0);

    const fonsTCoordAttrib = 1;
    gl.enableVertexAttribArray(fonsTCoordAttrib);
    state.tcoordBuffer.bind(gl.BufferTarget.array_buffer);
    const TCoordFormat = packed struct {
        u: f32,
        v: f32,
    };
    gl.bufferData(gl.BufferTarget.array_buffer, TCoordFormat, @ptrCast([*]const TCoordFormat, tcoords)[0..@intCast(usize, nverts)], gl.BufferUsage.dynamic_draw);
    gl.vertexAttribPointer(fonsTCoordAttrib, 2, gl.Type.float, false, 0, 0);

    const fonsColorAttrib = 2;
    gl.enableVertexAttribArray(fonsColorAttrib);
    state.colorBuffer.bind(gl.BufferTarget.array_buffer);
    gl.bufferData(gl.BufferTarget.array_buffer, u32, @ptrCast([*]const u32, colors)[0..@intCast(usize, nverts)], gl.BufferUsage.dynamic_draw);
    gl.vertexAttribPointer(fonsColorAttrib, 4, gl.Type.unsigned_byte, true, 0, 0);

    gl.drawArrays(gl.PrimitiveType.triangles, 0, @intCast(usize, nverts));

    gl.disableVertexAttribArray(fonsVertexAttrib);
    gl.disableVertexAttribArray(fonsTCoordAttrib);
    gl.disableVertexAttribArray(fonsColorAttrib);

    gl.bindVertexArray(gl.VertexArray.invalid);
}

fn fonsRenderDelete( userPtr: ?*anyopaque ) callconv(.C) void {
    const state = @ptrCast(*GlState, @alignCast(@alignOf(*GlState), userPtr.?));
    if (state.texture != gl.Texture.invalid) {
        state.texture.delete();
    }
}


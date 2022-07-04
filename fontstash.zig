const std = @import("std");

const c = @cImport({
    @cDefine("FONS_STATIC", {});
    @cInclude("upstream/fontstash.h");
});

const Error = error {
    Invalid
};

pub const Params = c.FONSparams;

// Horizontal align
pub const AlignLeft     = 1<<0; // Default
pub const AlignCenter   = 1<<1;
pub const AlignRight    = 1<<2;
// Vertical align
pub const AlignTop      = 1<<3;
pub const AlignMiddle   = 1<<4;
pub const AlignBottom   = 1<<5;
pub const AlignBaseline = 1<<6; // Default

pub const Bounds = struct {
    minx: f32,
    miny: f32,
    maxx: f32,
    maxy: f32,
};

pub const TextIterator = struct {
    iter: c.FONStextIter,
};

pub const Quad = struct {
    x0: f32,
    y0: f32,
    s0: f32,
    t0: f32,
    x1: f32,
    y1: f32,
    s1: f32,
    t1: f32,
};

pub fn createInternal(params: *Params) !Context {
    const result = c.fonsCreateInternal(params);
    return if (result == null) Error.Invalid else Context{ .context = result.? };
}

pub const Context = struct {
    context: *c.FONScontext,

    pub fn deleteInternal(self: *Context) void {
        c.fonsDeleteInternal(self.context);
    }

    // Returns current atlas size.
    pub fn getAtlasSize(self: *Context) struct { width: i32, height: i32 } {
        var atlasWidth: c_int = undefined;
        var atlasHeight: c_int = undefined;
        c.fonsGetAtlasSize( self.context, &atlasWidth, &atlasHeight );
        return .{ .width = @intCast( i32, atlasWidth ), .height = @intCast( i32, atlasHeight ) };
    }
    // Expands the atlas size. 
    pub fn expandAtlas(self: *Context, width: i32, height: i32) bool {
        return c.fonsExpandAtlas( self.context, @intCast(c_int, width ), @intCast(c_int, height) ) == 1;
    }
    // Resets the whole stash.
    pub fn resetAtlas(self: *Context, width: i32, height: i32) bool {
        return c.fonsResetAtlas( self.context, @intCast(c_int, width), @intCast(c_int, height ) ) == 1;
    }

    // Add fonts
    pub fn addFont(self: *Context, name: [*:0]const u8, path: [*:0]const u8) Error!i32 {
        const result = c.fonsAddFont( self.context, name, path );
        return if (result == c.FONS_INVALID) Error.Invalid else result;
    }
    pub fn addFontMem(self: *Context, name: [*:0]const u8, data: []const u8, freeData: bool) Error!i32 {
        const result = c.fonsAddFontMem( self.context, name, data.ptr, data.len, @boolToInt( freeData ) );
        return if (result == c.FONS_INVALID) Error.Invalid else result;
    }
    pub fn getFontByName(self: *Context, name: [*:0]const u8) Error!i32 {
        const result = c.fonsGetFontByName( self.context, name );
        return if (result == c.FONS_INVALID) Error.Invalid else result;
    }
    pub fn addFallbackFont(self: *Context, base: i32, fallback: i32) bool {
        return c.fonsAddFallbackFont( self.context, @intCast(c_int, base), @intCast(c_int, fallback) ) == 1;
    }

    // State handling
    pub fn pushState(self: *Context) void {
        c.fonsPushState( self.context );
    }
    pub fn popState(self: *Context) void {
        c.fonsPopState( self.context );
    }
    pub fn clearState(self: *Context) void {
        c.fonsClearState( self.context );
    }

    // State setting
    pub fn setSize(self: *Context, size: f32) void {
        c.fonsSetSize( self.context, size );
    }
    pub fn setColor(self: *Context, color: u32) void {
        c.fonsSetColor( self.context, @intCast(c_uint, color) );
    }
    pub fn setSpacing(self: *Context, spacing: f32) void {
        c.fonsSetSpacing( self.context, spacing );
    }
    pub fn setBlur(self: *Context, blur: f32) void {
        c.fonsSetBlur( self.context, blur );
    }
    pub fn setAlign(self: *Context, alignment: i32) void {
        c.fonsSetAlign( self.context, @intCast(c_int, alignment) );
    }
    pub fn setFont(self: *Context, font: i32) void {
        c.fonsSetFont( self.context, @intCast(c_int, font) );
    }

    // Draw text
    pub fn drawText(self: *Context, x: f32, y: f32, string: []const u8) f32 {
        //return c.fonsDrawText( self.context, x, y, string.ptr, string.ptr + string.len );
        return c.fonsDrawText( self.context, x, y, string.ptr, null );
    }

    // Measure text
    pub fn textBounds(self: *Context, x: f32, y: f32, string: []const u8, bounds: ?*Bounds) f32 {
        var boundsArray: [4]f32 = undefined;
        const advance = c.fonsTextBounds( self.context, x, y, string.ptr, string.ptr + string.len, &boundsArray );
        if ( bounds != null ) {
            bounds.minx = boundsArray[0];
            bounds.miny = boundsArray[1];
            bounds.maxx = boundsArray[2];
            bounds.maxx = boundsArray[3];
        }
        return advance;
    }
    pub fn lineBounds(self: *Context, y: f32) struct { miny: f32, maxy: f32 } {
        var miny: f32 = undefined;
        var maxy: f32 = undefined;
        c.fonsLineBounds( self.context, y, &miny, &maxy );
        return .{ .miny = miny, .maxy = maxy };
    }
    pub fn vertMetrics(self: *Context) struct { ascender: f32, descender: f32, lineh: f32 } {
        var ascender: f32 = undefined;
        var descender: f32 = undefined;
        var lineh: f32 = undefined;
        c.fonsVertMetrics( self.context, &ascender, &descender, &lineh );
        return .{ .ascender = ascender, .descender = descender, .lineh = lineh };
    }

    // Text iterator
    pub fn textIterInit(self: *Context, iter: *TextIterator, x: f32, y: f32, string: []const u8) bool {
        return c.fonsTextIterInit( self.context, &iter.iter, x, y, string.ptr, string.ptr + string.len ) == 1;
    }
    pub fn textIterNext(self: *Context, iter: *TextIterator, quad: ?*Quad) bool {
        var quadArray: [8]f32 = undefined;
        const result = c.fonsTextIterNext( self.context, &iter.iter, &quadArray );
        if ( quad != null ) {
            quad.x0 = quadArray[0];
            quad.y0 = quadArray[1];
            quad.s0 = quadArray[2];
            quad.t0 = quadArray[3];
            quad.x1 = quadArray[4];
            quad.y1 = quadArray[5];
            quad.s1 = quadArray[6];
            quad.t1 = quadArray[7];
        }
        return result == 1;
    }

    // Pull texture changes
    pub fn getTextureData(self: *Context) struct { data: [*]const u8, width: i32, height: i32 } {
        var width: c_int = undefined;
        var height: c_int = undefined;
        const data = c.fonsGetTextureData( self.context, &width, &height );
        return .{ .data = data, .width = @intCast( i32, width ), .height = @intCast( i32, height ) };
    }
    pub fn validateTexture(self: *Context) struct { valid: bool, dirty: bool } {
        var dirty: c_int = undefined;
        const valid = c.fonsValidateTexture( self.context, &dirty );
        return .{ .valid = valid == 1, .dirty = dirty == 1 };
    }

    // Draws the stash texture for debugging
    pub fn drawDebug(self: *Context, x: f32, y: f32) void {
        c.fonsDrawDebug( self.context, x, y );
    }
};


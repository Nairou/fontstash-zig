const std = @import("std");
const fons = @import("fontstash");
const glfw = @import("glfw");
const gl = @import("deps/zgl/zgl.zig");
const glfons = @import("glfontstash");

pub fn main() anyerror!void {
    // Window init
    try glfw.init( .{} );
    defer glfw.terminate();

    const window = try glfw.Window.create( 1024, 768, "Fontstash Example", null, null, .{
        .context_version_major = 4,
        .context_version_minor = 5,
        .opengl_forward_compat = true,
        .opengl_profile = .opengl_core_profile,
    } );
    defer window.destroy();

    try glfw.makeContextCurrent( window );
    try glfw.swapInterval( 1 );

    if ( !gl.loadExtensions( glfw.getProcAddress ) ) {
        std.log.info( "Error loading Glad", .{} );
        return Error.InitFail;
    }

    const shader = try exampleShader();


    // Fontstash init
    var fontstashGlState: glfons.GlState = .{};
    var fc = try glfons.create( &fontstashGlState, 1024, 1024, glfons.ZeroPosition.TopLeft );
    var fontNormal = try fc.addFont( "sans", "DroidSerif-Regular.ttf" );
    var fontItalic = try fc.addFont( "sans-italic", "DroidSerif-Italic.ttf" );
    var fontBold = try fc.addFont( "sans-bold", "DroidSerif-Bold.ttf" );
    var fontJapanese = try fc.addFont( "sans-jp", "DroidSansJapanese.ttf" );

    // Render loop
    while ( !window.shouldClose() ) {
        const windowSize = try window.getSize();
        // Update and render
        gl.viewport(0, 0, windowSize.width, windowSize.height);
        gl.clearColor(0.3, 0.3, 0.32, 1.0);
        gl.clear( .{ .color = true, .depth = true, .stencil = false } );
        gl.enable( gl.Capabilities.blend );
        gl.blendFunc( gl.BlendFactor.src_alpha, gl.BlendFactor.one_minus_src_alpha );

        gl.useProgram( shader.program );
        gl.uniform2i( shader.uniformWindowSize, @intCast( i32, windowSize.width ), @intCast( i32, windowSize.height ) );

        const white = glfons.color2int(255,255,255,255);
        const brown = glfons.color2int(192,128,0,128);
        const blue = glfons.color2int(0,192,255,255);
        const black = glfons.color2int(0,0,0,255);

        var sx: f32 = 50;
        var sy: f32 = 50;

        var dx: f32 = sx;
        var dy: f32 = sy;

        var lh: f32 = 0;

        fc.clearState();

        fc.setSize(124.0);
        fc.setFont(fontNormal);
        lh = fc.vertMetrics().lineh;
        dx = sx;
        dy += lh;

        fc.setSize(124.0);
        fc.setFont(fontNormal);
        fc.setColor(white);
        dx = fc.drawText(dx,dy,"The quick ");

        fc.setSize(48.0);
        fc.setFont(fontItalic);
        fc.setColor(brown);
        dx = fc.drawText(dx,dy,"brown ");

        fc.setSize(24.0);
        fc.setFont(fontNormal);
        fc.setColor(white);
        dx = fc.drawText(dx,dy,"fox ");

        lh = fc.vertMetrics().lineh;
        dx = sx;
        dy += lh*1.2;
        fc.setFont(fontItalic);
        dx = fc.drawText(dx,dy,"jumps over ");
        fc.setFont(fontBold);
        dx = fc.drawText(dx,dy,"the lazy ");
        fc.setFont(fontNormal);
        dx = fc.drawText(dx,dy,"dog.");

        dx = sx;
        dy += lh*1.2;
        fc.setSize(12.0);
        fc.setFont(fontNormal);
        fc.setColor(blue);
        _ = fc.drawText(dx,dy,"Now is the time for all good men to come to the aid of the party.");

        lh = fc.vertMetrics().lineh;
        dx = sx;
        dy += lh*1.2*2;
        fc.setSize(18.0);
        fc.setFont(fontItalic);
        fc.setColor(white);
        _ = fc.drawText(dx,dy,"Ég get etið gl.er án þess að meiða mig.");

        lh = fc.vertMetrics().lineh;
        dx = sx;
        dy += lh*1.2;
        fc.setFont(fontJapanese);
        _ = fc.drawText(dx,dy,"私はガラスを食べられます。それは私を傷つけません。");

        // Font alignment
        fc.setSize(18.0);
        fc.setFont(fontNormal);
        fc.setColor(white);

        dx = 50; dy = 350;
        fc.setAlign(fons.AlignLeft | fons.AlignTop);
        dx = fc.drawText(dx,dy,"Top");
        dx += 10;
        fc.setAlign(fons.AlignLeft | fons.AlignMiddle);
        dx = fc.drawText(dx,dy,"Middle");
        dx += 10;
        fc.setAlign(fons.AlignLeft | fons.AlignBaseline);
        dx = fc.drawText(dx,dy,"Baseline");
        dx += 10;
        fc.setAlign(fons.AlignLeft | fons.AlignBottom);
        _ = fc.drawText(dx,dy,"Bottom");

        dx = 150; dy = 400;
        fc.setAlign(fons.AlignLeft | fons.AlignBaseline);
        _ = fc.drawText(dx,dy,"Left");
        dy += 30;
        fc.setAlign(fons.AlignCenter | fons.AlignBaseline);
        _ = fc.drawText(dx,dy,"Center");
        dy += 30;
        fc.setAlign(fons.AlignRight | fons.AlignBaseline);
        _ = fc.drawText(dx,dy,"Right");

        // Blur
        dx = 500; dy = 350;
        fc.setAlign(fons.AlignLeft | fons.AlignBaseline);

        fc.setSize(60.0);
        fc.setFont(fontItalic);
        fc.setColor(white);
        fc.setSpacing(5.0);
        fc.setBlur(10.0);
        _ = fc.drawText(dx,dy,"Blurry...");

        dy += 50.0;

        fc.setSize(18.0);
        fc.setFont(fontBold);
        fc.setColor(black);
        fc.setSpacing(0.0);
        fc.setBlur(3.0);
        _ = fc.drawText(dx,dy+2,"DROP THAT SHADOW");

        fc.setColor(white);
        fc.setBlur(0);
        _ = fc.drawText(dx,dy,"DROP THAT SHADOW");

        try window.swapBuffers();
    }
}





// GL shader used for example

const ExampleShader = struct {
    program: gl.Program,
    uniformWindowSize: gl.UInt,
};

const Error = error {
    InitFail
};

pub fn exampleShader() !ExampleShader {
    // Shader setup
    const vertSource = 
        \\#version 450
        \\
        \\uniform ivec2 WindowSize;
        \\
        \\layout(location=0) in vec2 position;
        \\layout(location=1) in vec2 texture0;
        \\layout(location=2) in vec4 color;
        \\
        \\struct vertexData {
        \\  vec2 texture0;
        \\  vec4 color;
        \\};
        \\out vertexData data;
        \\
        \\void main()
        \\{
        \\  gl_Position = vec4( 2.0 * position.x / WindowSize.x - 1.0, 1.0 - 2.0 * position.y / WindowSize.y, 0, 1);
        \\  data.texture0 = texture0;
        \\  data.color = color;
        \\}
        ;
    const fragSource =
        \\#version 450
        \\
        \\uniform sampler2D textureSampler;
        \\
        \\struct vertexData {
        \\  vec2 texture0;
        \\  vec4 color;
        \\};
        \\in vertexData data;
        \\
        \\layout(location=0) out vec4 outColor;
        \\
        \\void main()
        \\{
        \\  outColor = texture( textureSampler, data.texture0 ) * data.color;
        \\}
        ;
    const vertexShader = gl.createShader( gl.ShaderType.vertex );
    errdefer vertexShader.delete();
    vertexShader.source( 1, &[1][]const u8{ vertSource } );
    vertexShader.compile();
    if ( vertexShader.get( gl.ShaderParameter.compile_status ) == 0 ) {
        std.log.err( "Error compiling vertex shader", .{} );
        return Error.InitFail;
    }
    const fragmentShader = gl.createShader( gl.ShaderType.fragment );
    errdefer fragmentShader.delete();
    fragmentShader.source( 1, &[1][]const u8{ fragSource } );
    fragmentShader.compile();
    if ( fragmentShader.get( gl.ShaderParameter.compile_status ) == 0 ) {
        std.log.err( "Error compiling fragment shader", .{} );
        return Error.InitFail;
    }
    const shaderProgram = gl.createProgram();
    shaderProgram.attach( vertexShader );
    shaderProgram.attach( fragmentShader );
    shaderProgram.link();
    if ( shaderProgram.get( gl.ProgramParameter.link_status ) == 0 ) {
        std.log.err( "Error linking shader program", .{} );
        return Error.InitFail;
    }
    const uniformWindowSize = shaderProgram.uniformLocation( "WindowSize" );

    return ExampleShader{
        .program = shaderProgram,
        .uniformWindowSize = uniformWindowSize.?,
    };
}


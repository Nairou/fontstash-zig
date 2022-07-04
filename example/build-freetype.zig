const std = @import("std");

const libroot = "deps/freetype";

pub fn buildLibrary(b: *std.build.Builder, mode: std.builtin.Mode, target: std.zig.CrossTarget) *std.build.LibExeObjStep {
    const lib = b.addStaticLibrary("freetype", libroot ++ "/src/base/ftbase.c");
    lib.defineCMacro("FT2_BUILD_LIBRARY", "1");
    lib.setBuildMode(mode);
    lib.setTarget(target);
    lib.linkLibC();
    lib.addIncludePath(libroot ++ "/include");

    const targetInfo = (std.zig.system.NativeTargetInfo.detect(b.allocator, target) catch unreachable).target;

    if (targetInfo.os.tag == .windows) {
        lib.addCSourceFile(libroot ++ "/builds/windows/ftsystem.c", &.{});
        lib.addCSourceFile(libroot ++ "/builds/windows/ftdebug.c", &.{});
    } else {
        lib.addCSourceFile(libroot ++ "/src/base/ftsystem.c", &.{});
        lib.addCSourceFile(libroot ++ "/src/base/ftdebug.c", &.{});
    }
    if (targetInfo.os.tag == .linux) {
        lib.defineCMacro("HAVE_UNISTD_H", "1");
        lib.defineCMacro("HAVE_FCNTL_H", "1");
        lib.addCSourceFile(libroot ++ "/builds/unix/ftsystem.c", &.{});
    }
    if (targetInfo.os.tag == .macos) {
        lib.addCSourceFile(libroot ++ "/src/base/ftmac.c", &.{});
    }

    lib.addCSourceFiles(freetype_base_sources, &.{});
    //lib.install();
    return lib;
}

const freetype_base_sources = &[_][]const u8{
    libroot ++ "/src/autofit/autofit.c",
    libroot ++ "/src/base/ftbbox.c",
    libroot ++ "/src/base/ftbdf.c",
    libroot ++ "/src/base/ftbitmap.c",
    libroot ++ "/src/base/ftcid.c",
    libroot ++ "/src/base/ftfstype.c",
    libroot ++ "/src/base/ftgasp.c",
    libroot ++ "/src/base/ftglyph.c",
    libroot ++ "/src/base/ftgxval.c",
    libroot ++ "/src/base/ftinit.c",
    libroot ++ "/src/base/ftmm.c",
    libroot ++ "/src/base/ftotval.c",
    libroot ++ "/src/base/ftpatent.c",
    libroot ++ "/src/base/ftpfr.c",
    libroot ++ "/src/base/ftstroke.c",
    libroot ++ "/src/base/ftsynth.c",
    libroot ++ "/src/base/fttype1.c",
    libroot ++ "/src/base/ftwinfnt.c",
    libroot ++ "/src/bdf/bdf.c",
    libroot ++ "/src/bzip2/ftbzip2.c",
    libroot ++ "/src/cache/ftcache.c",
    libroot ++ "/src/cff/cff.c",
    libroot ++ "/src/cid/type1cid.c",
    libroot ++ "/src/gzip/ftgzip.c",
    libroot ++ "/src/lzw/ftlzw.c",
    libroot ++ "/src/pcf/pcf.c",
    libroot ++ "/src/pfr/pfr.c",
    libroot ++ "/src/psaux/psaux.c",
    libroot ++ "/src/pshinter/pshinter.c",
    libroot ++ "/src/psnames/psnames.c",
    libroot ++ "/src/raster/raster.c",
    libroot ++ "/src/sdf/sdf.c",
    libroot ++ "/src/sfnt/sfnt.c",
    libroot ++ "/src/smooth/smooth.c",
    libroot ++ "/src/svg/svg.c",
    libroot ++ "/src/truetype/truetype.c",
    libroot ++ "/src/type1/type1.c",
    libroot ++ "/src/type42/type42.c",
    libroot ++ "/src/winfonts/winfnt.c",
};

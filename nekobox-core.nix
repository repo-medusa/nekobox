{
  buildGoModule,
  src,
  extraSources,
}:

buildGoModule rec {
  pname = "nekobox-core";
  version = "1.19";
  inherit src;
  sourceRoot = "${src.name}/go/cmd/nekobox_core";

  postPatch = ''
    cp -r --no-preserve=all ${extraSources.libneko} ../../../../libneko
    cp -r --no-preserve=all ${extraSources.sing-box} ../../../../sing-box
  '';

  vendorHash = "sha256-JdnGITJAVAK88TktjawmpdJKCujV0fxNqeRhVJ5PqsU=";

  ldflags = [
    "-w"
    "-s"
    "-X github.com/MatsuriDayo/libneko/neko_common.Version_neko=${version}"
  ];

  tags = [
    "with_clash_api"
    "with_gvisor"
    "with_quic"
    "with_wireguard"
    "with_utls"
    "with_ech"
  ];
}

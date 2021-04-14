FROM ghcr.io/juliapluto/pluto-slider-server@sha256:d2f130024b240e217a1d00bdb534e91a2ecce8ba49c6ac1658175d59eceb8919

EXPOSE 80

CMD [ "julia", "-e", "using PlutoSliderServer; cli()", "--", "--port", "80", "--host", "0.0.0.0", "--run-test-server-shortcut"]


FROM ghcr.io/juliapluto/pluto-slider-server@sha256:ab407b70a0c6506dfbdf2f1976f87a9bc10532d83c07e1ab14a95fa23e5134f8

EXPOSE 80

CMD [ "julia", "-e", "using PlutoSliderServer; cli()", "--", "--port", "80", "--host", "0.0.0.0", "--run-test-server-shortcut"]


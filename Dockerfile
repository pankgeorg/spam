FROM ghcr.io/juliapluto/pluto-slider-server@sha256:2951100de611c0fa32997454153e40c0ee989117606f28fb3e42481502d8717c

EXPOSE 80

CMD [ "julia", "-e", "using PlutoSliderServer; cli()", "--", "--port", "80", "--host", "0.0.0.0", "--run-test-server-shortcut"]


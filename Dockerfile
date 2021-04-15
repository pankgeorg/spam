FROM ghcr.io/juliapluto/pluto-slider-server@sha256:6a34c370fcb38e54d51582ac9b46ce02109ef7f1c6d96096580e8140652eb4e5

EXPOSE 80

CMD [ "julia", "-e", "using PlutoSliderServer; cli()", "--", "--port", "80", "--host", "0.0.0.0", "--run-test-server-shortcut"]


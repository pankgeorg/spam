FROM ghcr.io/juliapluto/pluto-slider-server@sha256:bc4fad96ff824b3f9b7b281282b18de19efbdbc3fa70895fa7d49f2440dca9f3

EXPOSE 80

CMD [ "julia", "-e", "using PlutoSliderServer; cli()", "--", "--port", "80", "--host", "0.0.0.0", "--run-test-server-shortcut"]


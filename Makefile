
.PHONY: deps

install:
	mix setup

run:
	iex -S mix phx.server

deps:
	mix deps.compile
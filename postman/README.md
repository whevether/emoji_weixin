# KLIPY transport regression tests

The mock uses the response shape consumed by this repository's KlipyClient and
small raster fixtures. It is a local test contract, not a full KLIPY API spec.
The provider's published mocks could not be searched because the CLI is signed
out. No real API key or provider traffic is used.

Run in separate terminals from the repository root:

```sh
postman simulation run postman/simulations/klipy.sim.yaml --port 4917 --output ndjson
flutter test test/network_integration_test.dart --dart-define=SIMULATION_URL=http://127.0.0.1:4917/klipy
```

The tests exercise the actual Dart HTTP transport, including error responses,
malformed JSON, timeouts during headers and bodies, declared and streamed size
limits, and media signature validation. Inspect the simulation's request events
to confirm traffic reached the mock. These tests do not establish live KLIPY
availability or credential validity. Stop the simulation with Ctrl+C.

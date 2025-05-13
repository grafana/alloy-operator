# Contributing

## Dependencies
- `helm`
- `flux`
- `make`
- `kind`
- `minikube`

## Running tests locally

```shell
cd tests/integration/<test name>
make create-cluster
make run-tests
make delete-cluster
```

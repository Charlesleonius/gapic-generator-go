.PHONY : test

image:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build github.com/googleapis/gapic-generator-go/cmd/protoc-gen-go_gapic
	docker build -t gcr.io/gapic-images/gapic-generator-go .
	rm protoc-gen-go_gapic

test-go-cli:
	go test github.com/googleapis/gapic-generator-go/internal/gencli
	./cmd/protoc-gen-go_cli/test.sh

test-gapic:
	go test github.com/googleapis/gapic-generator-go/internal/gengapic

golden:
	go test github.com/googleapis/gapic-generator-go/internal/gengapic -update_golden

test:
	go test -mod=mod ./...
	go install ./cmd/protoc-gen-go_gapic
	cd showcase && ./showcase.bash && cd .. && ./test.sh

install:
	go install ./cmd/protoc-gen-go_gapic
	go install ./cmd/protoc-gen-go_cli

update-bazel-repos:
	bazel run //:gazelle -- update-repos -from_file=go.mod -prune -to_macro=repositories.bzl%com_googleapis_gapic_generator_go_repositories
	sed -i ''  "s/    \"go_repository\",//g" repositories.bzl
	bazel run //:gazelle -- update-repos -from_file=showcase/go.mod -to_macro=repositories.bzl%com_googleapis_gapic_generator_go_repositories
	sed -i ''  "s/    \"go_repository\",//g" repositories.bzl

gazelle:
	bazel run //:gazelle
	sed -i '' "s/extendedops_go_proto/extended_operations_go_proto/g" internal/gengapic/BUILD.bazel
	sed -i '' "s/@com_github_golang_protobuf\/\/protoc-gen-go\/plugin/@io_bazel_rules_go\/\/proto\/wkt:compiler_plugin_go_proto/g" cmd/protoc-gen-go_gapic/BUILD
	sed -i '' "s/@com_github_golang_protobuf\/\/protoc-gen-go\/plugin/@io_bazel_rules_go\/\/proto\/wkt:compiler_plugin_go_proto/g" cmd/protoc-gen-go_cli/BUILD.bazel

clean:
	rm -rf testdata
	rm -rf cmd/protoc-gen-go_cli/testprotos
	rm -rf cmd/protoc-gen-go_cli/testdata	
	rm -rf showcase/gen
	rm -f showcase/gapic-showcase
	rm -f showcase/showcase_grpc_service_config.json
	rm -f showcase/compliance_suite.json
	rm -f showcase/showcase_v1beta1.yaml
	cd showcase; go mod edit -dropreplace github.com/googleapis/gapic-showcase

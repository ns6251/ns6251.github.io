.PHONY: run image hugo

hugo:
	docker run -it --rm -v $(CURDIR):$(CURDIR) -w $(CURDIR) hugo $(ARGS)

run:
	docker run -it --rm -v $(CURDIR):$(CURDIR) -w $(CURDIR) -p 1313:1313 hugo server --bind 0.0.0.0

image:
	docker buildx build . -t hugo

docker build -t scadnano:latest .
docker run -it --rm -p 8080:8080 -v `pwd`:/scadnano scadnano:latest

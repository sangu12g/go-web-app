#using golang base image
FROM golang:1.22.5 as base
# setting the working directory to run the steps 
WORKDIR /app
# copying the go.nod files
COPY go.mod ./
#downloading the dependiencies
RUN go mod download
#copying the source code 
COPY . .
RUN go build -o mainapp .

##############multistage for reducing image size & for security
###### using lightweight base image
FROM gcr.io/distroless/base

##copy binary from previous stage
COPY --from=base /app/mainapp .
#copy static files from previous stage
COPY --from=base /app/static ./static
#exposing the port to access the application
EXPOSE 8080
# command to run the application
CMD ["./mainapp"]

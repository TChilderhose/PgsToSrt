FROM mcr.microsoft.com/dotnet/sdk:6.0 AS builder

RUN apt-get update && \
    apt-get install -y automake ca-certificates g++ git libtool libtesseract4 make pkg-config libc6-dev && \
    git clone https://github.com/tesseract-ocr/tessdata /tessdata && rm -rf /tessdata/.git && \
    find /tessdata -path "*traineddata" -not -path "*/script*" -not -path "*eng*" -type f -delete

COPY . /src
RUN cd /src && \
    dotnet restore  && \
    dotnet publish -c Release -f net6.0 -o /src/PgsToSrt/out

FROM mcr.microsoft.com/dotnet/runtime:6.0
WORKDIR /app
ENV LANGUAGE=eng
ENV INPUT=/input.sup
ENV OUTPUT=/output.srt
VOLUME /tessdata

COPY --from=builder /src/PgsToSrt/out .
COPY --from=builder /tessdata /tessdata
COPY entrypoint.sh /entrypoint.sh

RUN apt-get update && \
    apt-get install -y libtesseract4 \
    && chmod +x /entrypoint.sh
    
# Docker for Windows: EOL must be LF.
ENTRYPOINT /entrypoint.sh
############################################
# ImageMagick runtime image
############################################
FROM alpine:3.24.1

# renovate: datasource=repology depName=alpine_3_24/imagemagick versioning=loose
ARG IMAGEMAGICK_VERSION=7.1.2.30-r0
ARG BUILD_DATE
ARG VERSION

# OCI-compliant labels
LABEL org.opencontainers.image.title="ImageMagick on Alpine Linux" \
      org.opencontainers.image.description="Lightweight ImageMagick Docker image with common image format support built on Alpine Linux" \
      org.opencontainers.image.vendor="ragedunicorn" \
      org.opencontainers.image.authors="Michael Wiesendanger <michael.wiesendanger@gmail.com>" \
      org.opencontainers.image.source="https://github.com/ragedunicorn/docker-magick" \
      org.opencontainers.image.documentation="https://github.com/ragedunicorn/docker-magick/blob/master/README.md" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.base.name="docker.io/library/alpine:3.24.1"

# ImageMagick and its format delegates from the Alpine community repository.
# PNG and GIF coders are part of the main imagemagick package; JPEG, WebP,
# HEIC, SVG and TIFF live in delegate subpackages. All subpackages are built
# from the same aport, so they share the exact same version pin.
# ca-certificates provides the TLS trust store (family convention).
#
# font-dejavu is what makes text work at all. ImageMagick links freetype,
# fontconfig and raqm, but those are only the machinery: with no font file
# installed `magick -list font` comes back empty and every -annotate, -draw
# "text" and label: fails with "unable to read font `'", which reads like a
# broken argument rather than a missing package.
RUN apk add --no-cache \
    ca-certificates \
    font-dejavu \
    imagemagick=${IMAGEMAGICK_VERSION} \
    imagemagick-jpeg=${IMAGEMAGICK_VERSION} \
    imagemagick-webp=${IMAGEMAGICK_VERSION} \
    imagemagick-heic=${IMAGEMAGICK_VERSION} \
    imagemagick-svg=${IMAGEMAGICK_VERSION} \
    imagemagick-tiff=${IMAGEMAGICK_VERSION}

# Give ImageMagick a usable default font.
#
# font-dejavu puts the files on disk and fontconfig lists them, but ImageMagick
# resolves an unspecified font through type.xml, not through fontconfig. With no
# matching entry the default font is the empty string and every -annotate,
# -draw "text" and label: without an explicit -font fails with
# "unable to read font `'". The shipped type-dejavu.xml does not help: its
# glyphs point at URWGothic-Book.ttf and friends, which only font-urw-base35
# provides. The ghostscript include is kept as it ships.
RUN printf '%s\n' \
    '<?xml version="1.0"?>' \
    '<typemap>' \
    '  <include file="type-ghostscript.xml"/>' \
    '  <type name="helvetica" fullname="DejaVu Sans" family="DejaVu Sans" glyphs="/usr/share/fonts/dejavu/DejaVuSans.ttf"/>' \
    '  <type name="fixed" fullname="DejaVu Sans Mono" family="DejaVu Sans Mono" glyphs="/usr/share/fonts/dejavu/DejaVuSansMono.ttf"/>' \
    '</typemap>' \
    > /etc/ImageMagick-7/type.xml

# Create non-root user for running ImageMagick. A home directory is created
# deliberately (no -H): fontconfig, pulled in via the SVG delegate, wants a
# writable cache directory and warns on every run without one.
RUN adduser -D -s /sbin/nologin magick

# Create working directory for input/output files
WORKDIR /tmp/workdir

RUN chown -R magick:magick /tmp/workdir

USER magick

ENTRYPOINT ["magick"]

CMD ["-version"]

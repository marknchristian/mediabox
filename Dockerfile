FROM python:3.11-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    DISPLAY=:0 \
    PULSE_SERVER=unix:/run/pulse/native

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Audio
    pulseaudio \
    pulseaudio-utils \
    alsa-utils \
    # Browser
    chromium \
    chromium-driver \
    # System utilities
    wget \
    curl \
    git \
    supervisor \
    xvfb \
    x11vnc \
    # Network tools
    net-tools \
    iputils-ping \
    # Video player for IPTV
    vlc \
    vlc-plugin-base \
    # Flatpak for Plexamp
    flatpak \
    # Window manager for GUI applications
    openbox \
    # noVNC for web-based VNC access
    python3-websockify \
    python3-numpy \
    # Python build dependencies
    build-essential \
    libffi-dev \
    libssl-dev \
    # Home Assistant dependencies
    libjpeg-dev \
    zlib1g-dev \
    autoconf \
    libopenjp2-7 \
    libtiff6 \
    libturbojpeg0 \
    tzdata \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Flatpak applications
# Note: Spotify Flatpak requires user namespaces not available in containers
# Spotify will use web interface instead
RUN flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo \
    && flatpak install -y flathub com.plexamp.Plexamp \
    && flatpak install -y flathub tv.plex.PlexDesktop

# Create application directory
WORKDIR /app

# Install noVNC for web-based VNC viewing
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify \
    && ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Create necessary directories
RUN mkdir -p /app/dashboard \
    /app/scripts \
    /app/ha_config \
    /var/log/supervisor \
    /run/pulse

# Copy Python requirements and install
COPY requirements.txt /app/
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy application files
COPY dashboard/ /app/dashboard/
COPY scripts/ /app/scripts/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make scripts executable
RUN chmod +x /app/scripts/*.py /app/scripts/*.sh

# Create non-root user for security
RUN useradd -m -u 1000 mediabox && \
    chown -R mediabox:mediabox /app /var/log/supervisor /run/pulse

# Expose ports
# 8080: Flask Dashboard & API
# 8123: Home Assistant
# 5900: VNC (optional)
# 6080: noVNC web interface
EXPOSE 8080 8123 5900 6080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api/health || exit 1

# Start supervisor to manage all services (runs as root to manage other services)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]


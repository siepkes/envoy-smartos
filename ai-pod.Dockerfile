FROM fedora:43

# Install the Service Planet Root CA RSA certificate.
RUN cat > /etc/pki/ca-trust/source/anchors/service_planet_root_ca_rsa-1.crt << 'EOF'
-----BEGIN CERTIFICATE-----
MIIGejCCBGKgAwIBAgIUUtxFixpPUaPmSBjVxKZ4zmt53FUwDQYJKoZIhvcNAQEL
BQAwgcIxCzAJBgNVBAYTAk5MMRUwEwYDVQQIDAxadWlkLUhvbGxhbmQxEjAQBgNV
BAcMCVJvdHRlcmRhbTEmMCQGA1UECgwdU2VydmljZSBQbGFuZXQgUm90dGVyZGFt
IEIuVi4xDDAKBgNVBAsMA0lDVDEiMCAGA1UEAwwZU2VydmljZSBQbGFuZXQgUm9v
dCBSU0EtMTEuMCwGCSqGSIb3DQEJARYfYXV0b21hdGlzZXJpbmdAc2VydmljZXBs
YW5ldC5ubDAeFw0yMTAzMTgxNDQ5MzRaFw00MTAzMTMxNDQ5MzRaMIHCMQswCQYD
VQQGEwJOTDEVMBMGA1UECAwMWnVpZC1Ib2xsYW5kMRIwEAYDVQQHDAlSb3R0ZXJk
YW0xJjAkBgNVBAoMHVNlcnZpY2UgUGxhbmV0IFJvdHRlcmRhbSBCLlYuMQwwCgYD
VQQLDANJQ1QxIjAgBgNVBAMMGVNlcnZpY2UgUGxhbmV0IFJvb3QgUlNBLTExLjAs
BgkqhkiG9w0BCQEWH2F1dG9tYXRpc2VyaW5nQHNlcnZpY2VwbGFuZXQubmwwggIi
MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQC+EWMaT6HVrSeu4sffmthDqInr
C1thx2ZF4kO+Umpc7Nu6aZU/bR09fIl0PqIBm0q2/ybNTGZSZk61aDSWw9vS/qw6
C29XfsQiJsiEOLx4uOWe2AmxUfgA95i6G+x9rn9oAWYZHMfguHRnmrFeddQ89Lm0
wl8t2zuUMU1tIT5eKJyZT3B7CCCdMce3iO0eBpBUd/MVDFerz2rECzW+4AuhK9Ia
BHyWBWWY7qBuXnMJ2ppPR0G0z3zzlYbPAjAsJfgnd/8Z/ueLX/VU4IczC/Op4O0O
BD0naeNtwCLJsL5w2DLC3jMRiN+1b4ry331GFQlot52PaSILZTLF/BT88AuwF0aP
uUk7ut6h/wzkcdlv5ag7mXTfFw/gGqC1L43CguXhV+bLfqTslZFKUtm08B66yHQx
O8uW7KgZ8r3G8310YWyTGbwhoGlLbtZrJePHqUIH2Ir8o7apHhk/VrDjpUlnNbIy
1tquxv51AWF3zayfqs7RzYx6H8v4n1w397jQIipxeuaRF+kuWBe5UqLgksE1kQE0
jBb+hgKPGpQWayc+LNFeXB0iA3hAxq6YBPi9nF+nByjQKDCIUY2Zje3TazvwC5P7
qCUqN9ZG6WpdAG78svw6bvjAlzxovw8Pg5csSmiXJpBRToxmbFfdNf5iZTW8aC4M
/h6o3ykfGAGkxZNoJwIDAQABo2YwZDAdBgNVHQ4EFgQUP1uClhv9bH1m6oo4C7R/
5TuHRoAwHwYDVR0jBBgwFoAUP1uClhv9bH1m6oo4C7R/5TuHRoAwEgYDVR0TAQH/
BAgwBgEB/wIBATAOBgNVHQ8BAf8EBAMCAYYwDQYJKoZIhvcNAQELBQADggIBAGUi
rVIlVjHjytLbkbRH6XGb4NOHvUTj1NbLMFe8e8P9yhLEeMLCJeDmtqjmJRrn5/W8
xVYwLzcBP7f2kkMuVFphbHVOOULg1LzJxpkk7G+l5pmBaJHBj/oPKmkObs7lBPxd
dztkkpJlGA0MJ4lp78Fv/IW1k4sXSNQnQ3Ng7UGxANJfhtl5SMDnrRjZB5koeSN6
17XeT8P+UyyNHzCgXQuThpZu+iCWWec6RqsOZDfwl2UqDliHoQnTZ66y/jtdLeZC
BgpZPlfKk5GNhHBt4C5VxqvDtoWEpg4wPfGwrjj8VzA71+mEhv4Bw1hReVbW0kvb
eh/5YUTUhdySoJFV3ySNG3gD9SG5TnvZlLnTMXL0MXJl61VaRXJRj7W9x5eSPTPo
0+kbxY+EOprW7Y4TutXCk+51Zzbkrzcw9rYcr5Ogxk26ALn5Y4n5cSw5PHWu9lW3
21hxLyfYFeu9FTE0Y+0bE9BgCZRpf5jHchTtPFCv0K7kupiNukadBP4txszRUiXY
GQcC69kX9QEatSLfJhrYrOUl5ebK1HTwKFih8NjS3vnKs7vQg1Uh5rgAJefOPHzv
ea6D7whFipheWjdhmiQ47HgmFZIY2y73w6PIekjXienctLlcxzXFCmPQ2uTQ8uwc
VPbVbHR3tzda8hJQ7Y3JVj30ydZaL4QgVm95t+ox
-----END CERTIFICATE-----
EOF
RUN update-ca-trust

RUN rm -f /etc/yum.repos.d/*.repo && cat > /etc/yum.repos.d/all-repos.repo << 'EOF'
[fedora]
name=Fedora $releasever - $basearch (Service Planet mirror)
baseurl=https://enterprise-linux-repo.serviceplanet.nl/fedora/$releasever/stable/Everything/$basearch/os/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates]
name=Fedora $releasever - $basearch - Updates (Service Planet mirror)
baseurl=https://enterprise-linux-repo.serviceplanet.nl/fedora/$releasever/stable/Everything/$basearch/updates/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF

RUN dnf clean all && \
    dnf install -y --allowerasing \
    procps-ng \
    ca-certificates bubblewrap socat curl git vim-enhanced \
    ripgrep jq unzip \
    && dnf clean all

ARG HOST_GATEWAY
ARG AI_POD_VERSION
RUN curl -fsSL "http://${HOST_GATEWAY}:7822/install/claude.sh" | bash

WORKDIR /app

# ai-pod expects the UID and GID to be 1000.
RUN groupadd -g 1000 ai-pod && useradd -u 1000 -g 1000 -ms /bin/bash ai-pod && chown -R ai-pod:ai-pod /app

# System-level git identity (fallback when no host identity is provided)
RUN git config --system user.email "ai-pod@ai-pod" && \
    git config --system user.name "ai-pod" && \
    git config --global --add safe.directory /app

USER ai-pod

ENV PATH="/home/ai-pod/.local/bin:${PATH}"
ENV EDITOR=vim
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk

CMD ["claude"]

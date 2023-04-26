FROM alpine as keygen

# Install packages
RUN apk --no-cache add gnupg haveged tini

# Generate new private and public key with specified parameter
RUN echo "Key-Type: RSA" > keygen.conf && \
    echo "Key-Length: 4096" >> keygen.conf && \
    echo "Subkey-Type: RSA" >> keygen.conf && \
    echo "Subkey-Length: 4096" >> keygen.conf && \
    echo "Name-Real: nobody" >> keygen.conf && \
    echo "Name-Email: nobody@nowhere.com" >> keygen.conf && \
    echo "Expire-Date: 0" >> keygen.conf && \
    gpg --batch --pinentry-mode loopback --passphrase 'asdf' --gen-key keygen.conf

# Set working directory
WORKDIR /wd

# Export public and private key, and in private key case, supply the passphrase
RUN gpg --export --armor > /wd/public_key.asc
RUN gpg --export-secret-keys --armor --batch --yes --pinentry-mode loopback --passphrase 'asdf' > /wd/private_key.asc

# Pull latest ubuntu as encrypter docker stage
FROM ubuntu:latest as encrypter

# Install GnuPG and other necessary packages
RUN apt-get update
RUN apt-get install -y gnupg2 wget

WORKDIR /wd

# Copy your keypair into the container
COPY --from=keygen /wd/public_key.asc public_key.asc

# Import your keys into GnuPG
RUN gpg --import public_key.asc

# Create encrypted file
RUN echo "plain text message" | \
    gpg --trust-model always --output encryptedFile.gpg --encrypt -r nobody@nowhere.com --batch --yes

# Pull dotnet SDK to run C# decrypter app
FROM mcr.microsoft.com/dotnet/sdk:6.0

# Install GnuPG and other necessary packages
RUN apt-get update
RUN apt-get install -y gnupg2 wget

WORKDIR /wd

# Copy your keypair into the container
COPY --from=keygen /wd/*.asc .

# Copy encrypted file
COPY --from=encrypter /wd/encryptedFile.gpg .

# Import your keys into GnuPG
RUN gpg --batch --yes --pinentry-mode loopback --passphrase 'asdf' --import /wd/private_key.asc && gpg --import /wd/public_key.asc

# Install the app to container
COPY . .
RUN dotnet restore

# Run app with passphrase as first arg, and the file as second arg
CMD ["dotnet", "run", "asdf", "encryptedFile.gpg"]

#include "framework/core/protectedassetformat.h"

#include <openssl/evp.h>
#include <openssl/rand.h>

#include <algorithm>
#include <array>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

namespace {
using ProtectedAssets::Kind;

std::vector<uint8_t> readFile(const std::filesystem::path& path) {
    std::ifstream input(path, std::ios::binary | std::ios::ate);
    if (!input)
        throw std::runtime_error("unable to open input file: " + path.string());
    const auto end = input.tellg();
    if (end <= 0 || static_cast<uint64_t>(end) > ProtectedAssets::MaximumAssetSize)
        throw std::runtime_error("invalid input file size: " + path.string());
    std::vector<uint8_t> data(static_cast<size_t>(end));
    input.seekg(0);
    if (!input.read(reinterpret_cast<char*>(data.data()), static_cast<std::streamsize>(data.size())))
        throw std::runtime_error("unable to read input file: " + path.string());
    return data;
}

void writeU32(std::ofstream& output, const uint32_t value) {
    std::vector<uint8_t> bytes;
    ProtectedAssets::appendU32(bytes, value);
    output.write(reinterpret_cast<const char*>(bytes.data()), bytes.size());
}

void encryptAsset(std::ofstream& output, const std::vector<uint8_t>& input, const Kind kind,
                  const ProtectedAssets::Header& header, const std::vector<uint8_t>& encodedHeader,
                  const std::array<uint8_t, 32>& key) {
    const uint32_t chunks = ProtectedAssets::chunkCount(input.size(), header.chunkSize);
    for (uint32_t index = 0; index < chunks; ++index) {
        const size_t offset = static_cast<size_t>(index) * header.chunkSize;
        const uint32_t plainSize = static_cast<uint32_t>(std::min<size_t>(header.chunkSize, input.size() - offset));
        std::array<uint8_t, ProtectedAssets::NonceSize> nonce{};
        if (RAND_bytes(nonce.data(), nonce.size()) != 1)
            throw std::runtime_error("unable to generate a cryptographic nonce");

        const auto aad = ProtectedAssets::makeAad(encodedHeader, kind, index, plainSize);
        std::vector<uint8_t> cipher(plainSize + EVP_MAX_BLOCK_LENGTH);
        std::array<uint8_t, ProtectedAssets::TagSize> tag{};
        std::unique_ptr<EVP_CIPHER_CTX, decltype(&EVP_CIPHER_CTX_free)> context(EVP_CIPHER_CTX_new(), EVP_CIPHER_CTX_free);
        if (!context)
            throw std::runtime_error("unable to allocate cipher context");

        int written = 0;
        int finalWritten = 0;
        int aadWritten = 0;
        if (EVP_EncryptInit_ex(context.get(), EVP_aes_256_gcm(), nullptr, nullptr, nullptr) != 1 ||
            EVP_CIPHER_CTX_ctrl(context.get(), EVP_CTRL_GCM_SET_IVLEN, nonce.size(), nullptr) != 1 ||
            EVP_EncryptInit_ex(context.get(), nullptr, nullptr, key.data(), nonce.data()) != 1 ||
            EVP_EncryptUpdate(context.get(), nullptr, &aadWritten, aad.data(), static_cast<int>(aad.size())) != 1 ||
            EVP_EncryptUpdate(context.get(), cipher.data(), &written, input.data() + offset, plainSize) != 1 ||
            EVP_EncryptFinal_ex(context.get(), cipher.data() + written, &finalWritten) != 1 ||
            EVP_CIPHER_CTX_ctrl(context.get(), EVP_CTRL_GCM_GET_TAG, tag.size(), tag.data()) != 1)
            throw std::runtime_error("unable to encrypt asset chunk");

        cipher.resize(static_cast<size_t>(written + finalWritten));
        output.write(reinterpret_cast<const char*>(nonce.data()), nonce.size());
        writeU32(output, static_cast<uint32_t>(cipher.size()));
        output.write(reinterpret_cast<const char*>(cipher.data()), cipher.size());
        output.write(reinterpret_cast<const char*>(tag.data()), tag.size());
    }
}
} // namespace

int main(int argc, char** argv) {
    try {
        if (argc != 4) {
            std::cerr << "Usage: otclient_asset_packer <Tibia.dat> <Tibia.spr> <assets.sec>\n"
                         "Set OTCLIENT_ASSET_KEY_HEX to exactly 64 hexadecimal characters.\n";
            return 2;
        }
        const char* keyHex = std::getenv("OTCLIENT_ASSET_KEY_HEX");
        if (!keyHex)
            throw std::runtime_error("OTCLIENT_ASSET_KEY_HEX is not set");
        const auto key = ProtectedAssets::parseKey(keyHex);
        const auto dat = readFile(argv[1]);
        const auto spr = readFile(argv[2]);

        ProtectedAssets::Header header{
            ProtectedAssets::Version,
            ProtectedAssets::DefaultChunkSize,
            dat.size(),
            spr.size(),
            ProtectedAssets::chunkCount(dat.size(), ProtectedAssets::DefaultChunkSize),
            ProtectedAssets::chunkCount(spr.size(), ProtectedAssets::DefaultChunkSize)
        };
        const auto encodedHeader = ProtectedAssets::encodeHeader(header);

        std::ofstream output(argv[3], std::ios::binary | std::ios::trunc);
        if (!output)
            throw std::runtime_error("unable to create output container");
        output.write(reinterpret_cast<const char*>(encodedHeader.data()), encodedHeader.size());
        encryptAsset(output, dat, Kind::Dat, header, encodedHeader, key);
        encryptAsset(output, spr, Kind::Spr, header, encodedHeader, key);
        output.close();
        if (!output)
            throw std::runtime_error("unable to finish output container");

        std::cout << "Created " << argv[3] << " with " << header.datChunks << " DAT chunks and "
                  << header.sprChunks << " SPR chunks.\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "asset packer: " << error.what() << '\n';
        return 1;
    }
}

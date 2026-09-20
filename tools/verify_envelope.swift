// Public release verifier. It contains no DiceCraft engine or private key.
import CryptoKit
import Foundation

struct Envelope: Decodable { let payload: String; let signature: String }
struct Payload: Decodable { let manifest: String; let files: [String:String] }
struct Manifest: Decodable {
    let schemaVersion: Int; let contentVersion: Int; let minimumBuild: Int
    let files: [String]; let hashes: [String:String]
}
enum Invalid: Error { case arguments, size, key, signature, manifest, files, digest, mirror }
let allowed = Set(["dice/catalog.json", "cocktails/catalog.json", "balance/global.json",
    "loot/rarity.json", "maps/templates.json", "monsters/catalog.json",
    "text/strings.json", "assets/manifest.json"])

do {
    guard CommandLine.arguments.count == 2 else { throw Invalid.arguments }
    let root = URL(fileURLWithPath:CommandLine.arguments[1],isDirectory:true)
    let data = try Data(contentsOf:root.appendingPathComponent("release.json"))
    guard data.count > 0, data.count <= 4*1024*1024 else { throw Invalid.size }
    let keyText = try String(contentsOf:root.appendingPathComponent("public-key.txt"),encoding:.utf8)
    guard let key = Data(base64Encoded:keyText.trimmingCharacters(in:.whitespacesAndNewlines)), key.count == 32 else { throw Invalid.key }
    let envelope = try JSONDecoder().decode(Envelope.self,from:data)
    guard let payload = Data(base64Encoded:envelope.payload), let signature = Data(base64Encoded:envelope.signature),
          try Curve25519.Signing.PublicKey(rawRepresentation:key).isValidSignature(signature,for:payload) else { throw Invalid.signature }
    let pack = try JSONDecoder().decode(Payload.self,from:payload)
    guard let manifestData = Data(base64Encoded:pack.manifest) else { throw Invalid.manifest }
    let manifest = try JSONDecoder().decode(Manifest.self,from:manifestData)
    guard manifest.schemaVersion == 2, manifest.contentVersion >= 4, manifest.minimumBuild >= 399 else { throw Invalid.manifest }
    guard Set(manifest.files) == allowed, manifest.files.count == allowed.count,
          Set(manifest.hashes.keys) == allowed, Set(pack.files.keys) == allowed else { throw Invalid.files }
    guard try manifestData == Data(contentsOf:root.appendingPathComponent("manifest.json")) else { throw Invalid.mirror }
    for name in allowed {
        guard let encoded = pack.files[name], let content = Data(base64Encoded:encoded) else { throw Invalid.files }
        let hash = SHA256.hash(data:content).map { String(format:"%02x",$0) }.joined()
        guard hash == manifest.hashes[name] else { throw Invalid.digest }
        guard try content == Data(contentsOf:root.appendingPathComponent(name)) else { throw Invalid.mirror }
    }
    print("Verified public C\(manifest.contentVersion): Ed25519, eight SHA-256 digests and exact mirrors.")
} catch {
    FileHandle.standardError.write(Data("Public content verification failed: \(error)\n".utf8))
    exit(1)
}

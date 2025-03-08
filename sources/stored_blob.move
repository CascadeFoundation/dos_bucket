module dos_bucket::stored_blob;

use dos_bucket::bucket::{Bucket, BucketAdminCap};

// A `StoredBlob` is a reference to a `Blob` that's been stored in a `Bucket`.
public struct StoredBlob has key, store {
    id: UID,
    // The ID of the `Bucket` that contains the `Blob`.
    bucket_id: ID,
    // The ID of the `Blob` in the `Bucket`.
    blob_id: u256,
    // The size of the `Blob`.
    blob_size: u64,
    // The encoding type of the `Blob`.
    blob_encoding_type: u8,
}

public fun new(
    cap: &BucketAdminCap,
    bucket: &Bucket,
    blob_id: u256,
    ctx: &mut TxContext,
): StoredBlob {
    bucket.authorize(cap);

    // Get a reference to the `Blob` from the `Bucket`.
    let blob = bucket.blobs().borrow(blob_id);
    // Create and return a `StoredBlob`.
    StoredBlob {
        id: object::new(ctx),
        bucket_id: object::id(bucket),
        blob_id: blob_id,
        blob_size: blob.size(),
        blob_encoding_type: blob.encoding_type(),
    }
}

public fun destroy(self: StoredBlob) {
    let StoredBlob { id, .. } = self;
    id.delete();
}

public fun id(self: &StoredBlob): ID {
    self.id.to_inner()
}

public fun bucket_id(self: &StoredBlob): ID {
    self.bucket_id
}

public fun blob_id(self: &StoredBlob): u256 {
    self.blob_id
}

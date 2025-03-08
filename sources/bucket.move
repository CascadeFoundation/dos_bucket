module dos_bucket::bucket;

use sui::event::emit;
use sui::object_table::{Self, ObjectTable};
use walrus::blob::Blob;

// A `Bucket` is a container for Walrus `Blob` objects.
public struct Bucket has key, store {
    id: UID,
    // The number of `Blob` objects in the `Bucket`.
    blob_count: u64,
    // A table of `Blob` objects in the `Bucket`, keyed by the Blob ID of the `Blob`.
    blobs: ObjectTable<u256, Blob>,
}

public struct BucketAdminCap has key, store {
    id: UID,
    bucket_id: ID,
}

public struct ReturnBlobPromise {
    blob_id: u256,
    bucket_id: ID,
}

public struct BucketCreatedEvent has copy, drop {
    bucket_id: ID,
    bucket_admin_cap_id: ID,
}

const EInvalidBucket: u64 = 0;
const EInvalidBlob: u64 = 1;

// Create a new `Bucket`.
public fun new(ctx: &mut TxContext): (Bucket, BucketAdminCap) {
    let bucket = Bucket {
        id: object::new(ctx),
        blobs: object_table::new(ctx),
        blob_count: 0,
    };

    let bucket_admin_cap = BucketAdminCap {
        id: object::new(ctx),
        bucket_id: bucket.id.to_inner(),
    };

    emit(BucketCreatedEvent {
        bucket_id: object::id(&bucket),
        bucket_admin_cap_id: object::id(&bucket_admin_cap),
    });

    (bucket, bucket_admin_cap)
}

// Add a `Blob` to a `Bucket`.
public fun add_blob(self: &mut Bucket, cap: &BucketAdminCap, blob: Blob) {
    self.authorize(cap);

    self.blob_count = self.blob_count + 1;
    self.blobs.add(blob.blob_id(), blob);
}

// Remove a `Blob` from a `Bucket`.
public fun remove_blob(self: &mut Bucket, cap: &BucketAdminCap, blob_id: u256): Blob {
    self.authorize(cap);

    self.blob_count = self.blob_count - 1;
    self.blobs.remove(blob_id)
}

// Borrow a `Blob` from a `Bucket`.
public fun borrow_blob(
    self: &mut Bucket,
    cap: &BucketAdminCap,
    blob_id: u256,
): (Blob, ReturnBlobPromise) {
    self.authorize(cap);

    let blob = self.blobs.remove(blob_id);
    let promise = ReturnBlobPromise {
        blob_id: blob_id,
        bucket_id: self.id.to_inner(),
    };
    (blob, promise)
}

// Return a `Blob` to a `Bucket`.
public fun return_blob(
    self: &mut Bucket,
    cap: &BucketAdminCap,
    promise: ReturnBlobPromise,
    blob: Blob,
) {
    self.authorize(cap);

    assert!(promise.bucket_id == self.id.to_inner(), EInvalidBucket);
    assert!(self.blobs.contains(promise.blob_id), EInvalidBlob);

    self.blobs.add(promise.blob_id, blob);

    let ReturnBlobPromise { .. } = promise;
}

// Get a mutable reference to the `UID` of a `Bucket`.
public fun uid_mut(self: &mut Bucket, cap: &BucketAdminCap): &mut UID {
    self.authorize(cap);

    &mut self.id
}

// Get a reference to the `ObjectTable` of `Blob` objects in a `Bucket`.
public(package) fun blobs(self: &Bucket): &ObjectTable<u256, Blob> {
    &self.blobs
}

// Get the number of `Blob` objects in a `Bucket`.
public fun blob_count(self: &Bucket): u64 {
    self.blob_count
}

public(package) fun authorize(self: &Bucket, cap: &BucketAdminCap) {
    assert!(self.id.to_inner() == cap.bucket_id, EInvalidBucket);
}

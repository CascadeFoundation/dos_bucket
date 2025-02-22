module dos_bucket::bucket;

use dos_bucket::admin::AdminCap;
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

public struct ReturnBlobPromise {
    blob_id: u256,
    bucket_id: ID,
}

const EInvalidBucket: u64 = 0;
const EInvalidBlob: u64 = 1;

// Create a new `Bucket`.
public fun new(ctx: &mut TxContext): Bucket {
    Bucket {
        id: object::new(ctx),
        blobs: object_table::new(ctx),
        blob_count: 0,
    }
}

// Add a `Blob` to a `Bucket`.
public fun add_blob(self: &mut Bucket, cap: &AdminCap, blob: Blob) {
    cap.authorize(self.id());

    self.blob_count = self.blob_count + 1;
    self.blobs.add(blob.blob_id(), blob);
}

// Remove a `Blob` from a `Bucket`.
public fun remove_blob(self: &mut Bucket, cap: &AdminCap, blob_id: u256): Blob {
    cap.authorize(self.id());

    self.blob_count = self.blob_count - 1;
    self.blobs.remove(blob_id)
}

// Borrow a `Blob` from a `Bucket`.
public fun borrow_blob(
    self: &mut Bucket,
    cap: &AdminCap,
    blob_id: u256,
): (Blob, ReturnBlobPromise) {
    cap.authorize(self.id());

    let blob = self.blobs.remove(blob_id);
    let promise = ReturnBlobPromise {
        blob_id: blob_id,
        bucket_id: self.id(),
    };
    (blob, promise)
}

// Return a `Blob` to a `Bucket`.
public fun return_blob(self: &mut Bucket, cap: &AdminCap, promise: ReturnBlobPromise, blob: Blob) {
    cap.authorize(self.id());

    assert!(promise.bucket_id == self.id(), EInvalidBucket);
    assert!(self.blobs.contains(promise.blob_id), EInvalidBlob);

    self.blobs.add(promise.blob_id, blob);

    let ReturnBlobPromise { .. } = promise;
}

// Get a mutable reference to the `UID` of a `Bucket`.
public fun uid_mut(self: &mut Bucket, cap: &AdminCap): &mut UID {
    cap.authorize(self.id());

    &mut self.id
}

// Get a reference to the `ObjectTable` of `Blob` objects in a `Bucket`.
public(package) fun blobs(self: &Bucket): &ObjectTable<u256, Blob> {
    &self.blobs
}

// Get the `ID` of a `Bucket`.
public fun id(self: &Bucket): ID {
    self.id.to_inner()
}

// Get the number of `Blob` objects in a `Bucket`.
public fun blob_count(self: &Bucket): u64 {
    self.blob_count
}

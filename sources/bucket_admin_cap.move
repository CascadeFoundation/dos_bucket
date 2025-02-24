module dos_bucket::admin;

public struct BucketAdminCap has key, store {
    id: UID,
    bucket_id: ID,
}

const EInvalidBucketId: u64 = 0;

public fun id(self: &BucketAdminCap): ID {
    self.id.to_inner()
}

public fun bucket_id(self: &BucketAdminCap): ID {
    self.bucket_id
}

public(package) fun authorize(self: &BucketAdminCap, bucket_id: ID) {
    assert!(self.bucket_id == bucket_id, EInvalidBucketId);
}

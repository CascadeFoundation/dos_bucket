module dos_bucket::admin;

public struct AdminCap has key, store {
    id: UID,
    bucket_id: ID,
}

const EInvalidBucketId: u64 = 0;

public fun id(self: &AdminCap): ID {
    self.id.to_inner()
}

public fun bucket_id(cap: &AdminCap): ID {
    cap.bucket_id
}

public(package) fun authorize(self: &AdminCap, bucket_id: ID) {
    assert!(self.bucket_id == bucket_id, EInvalidBucketId);
}

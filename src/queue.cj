package cjoy

public interface Queue<T> {
    func offer(item: T): Unit
    func poll(): ?T
    func peek(): ?T
    func clear(): Unit
    func size(): Int64
    func remove(item: T): Bool
}

/**
* Refer to Java implementation
*/
public class PriorityQueue<T> <: Queue<T> where T<: Comparable<T> & Equatable<T> {
    private static let DEFAULT_INITIAL_CAPACITY: Int64 = 11
    private static let MAX_ARRAY_SIZE = Int64.Max - 8;
    private var queue: Array<T>
    let zero: T = unsafe { zeroValue<T>() }
    var count = 0

    public init() {
        this(DEFAULT_INITIAL_CAPACITY)
    }

    public init(initialCapacity: Int64) {
        this.queue = Array<T>(initialCapacity, repeat: zero)
    }

    public func offer(item: T): Unit {
        let oldCount = count
        if (oldCount >= queue.size) {
            grow(oldCount +1)
        }
        count +=1
        if (oldCount == 0) {
            queue[0] = item
        } else {
            siftUp(oldCount, item)
        }
    }

    public func poll(): ?T {
        if (count == 0) {
            return Option<T>.None
        }
        count -= 1
        var lastIdx = count
        let res = queue[0]
        let lastItem = queue[lastIdx]
        queue[lastIdx] = zero
        if (lastIdx !=0) {
            siftDown(0, lastItem)
        }
        res
    }

    public func peek(): ?T {
        if ( count == 0) { Option<T>.None } else { Some(queue[0])}
    }

    public func clear(): Unit {
        while (poll().isSome()) {

        }
    }

    public func size(): Int64 {
        count
    }

    public func remove(item: T): Bool {
        let idx = indexOf(item)
        if (idx == -1) {
            return false
        }
        removeAt(idx)
        return true
    }

    private func grow(minCapacity: Int64): Unit {
        let oldCapacity: Int64 = queue.size
        // Double size if small; else grow by 50%
        var newCapacity: Int64 = oldCapacity +  if (oldCapacity < 64 ) { oldCapacity + 2 } else { oldCapacity >> 1 }
        if (newCapacity < minCapacity) {
            newCapacity = minCapacity
        }
        let newArr: Array<T> = Array<T>(newCapacity, repeat: zero)
        queue.copyTo(newArr, 0, 0, count)
        queue = newArr
    }

    private func siftDown(pos: Int64, item: T) {
        let half  = count >> 1
        var offset = pos
        while (offset < half) {
            var child = (offset << 1) +1
            var obj = queue[child]
            var right = child + 1
            if ( right < count && obj.compare(queue[right]) == Ordering.GT) {
                child = right
                obj = queue[child]
            }
            let res = obj.compare(queue[right])
            if ( res == Ordering.EQ || res == Ordering.LT ) {
                break
            }
            queue[offset] = obj
            offset = child
        }
        queue[offset] = item;
    }

    private func heapify(): Unit {
        let end = (count >>1) -1
        for (idx in end..=0:-1) {
            siftDown(idx, queue[idx])
        }
    }

    private func siftUp(pos: Int64, item: T) {
        var offset = pos
        while (offset >0) {
            var parent = (offset -1) >> 1
            var obj = queue[parent]
            let res = item.compare(obj)
            if ( res == Ordering.EQ || res == Ordering.GT){
                break;
            }
            queue[offset] = obj
            offset = parent
        }
        queue[offset] = item
    }

    private func indexOf(item: T): Int64 {
        for (idx in 0..count) {
            if (item == queue[idx]) {
                return idx
            }
        }
        return -1
    }

    private func removeAt(pos: Int64): ?T {
        count -= 1
        let lastIdx = count
        if (lastIdx == pos) {
            queue[pos] = zero
        } else {
            let moved = queue[pos]
            queue[lastIdx] = zero
            siftDown(pos, moved)
            if (queue[pos] == moved) {
                siftUp(pos, moved)
                if (queue[pos] != moved) {
                    return moved
                }
            }
        }
        Option<T>.None
    }
}
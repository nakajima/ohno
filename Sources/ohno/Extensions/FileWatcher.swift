//
// aus der Technik, on 16.05.23.
// https://www.ausdertechnik.de
//
// Based on: https://github.com/eonist/FileWatcher/tree/master
//

import Cocoa

public class FileWatcher {
	public typealias CallBack = (_ fileWatcherEvent: FileWatcherEvent) throws -> Void
	public var callback: CallBack?
	public var queue: DispatchQueue?

	let filePaths: [String] // -- paths to watch - works on folders and file paths
	var streamRef: FSEventStreamRef?
	var hasStarted: Bool { streamRef != nil }

	public init(_ paths: [String]) { self.filePaths = paths }

	/**
	 * - Parameters:
	 *    - streamRef: The stream for which event(s) occurred. clientCallBackInfo: The info field that was supplied in the context when this stream was created.
	 *    - numEvents:  The number of events being reported in this callback. Each of the arrays (eventPaths, eventFlags, eventIds) will have this many elements.
	 *    - eventPaths: An array of paths to the directories in which event(s) occurred. The type of this parameter depends on the flags
	 *    - eventFlags: An array of flag words corresponding to the paths in the eventPaths parameter. If no flags are set, then there was some change in the directory at the specific path supplied in this  event. See FSEventStreamEventFlags.
	 *    - eventIds: An array of FSEventStreamEventIds corresponding to the paths in the eventPaths parameter. Each event ID comes from the most recent event being reported in the corresponding directory named in the eventPaths parameter.
	 */
	let eventCallback: FSEventStreamCallback = { (
		_: ConstFSEventStreamRef,
		contextInfo: UnsafeMutableRawPointer?,
		numEvents: Int,
		eventPaths: UnsafeMutableRawPointer,
		eventFlags: UnsafePointer<FSEventStreamEventFlags>,
		eventIds: UnsafePointer<FSEventStreamEventId>
	) in
		let fileSystemWatcher = Unmanaged<FileWatcher>.fromOpaque(contextInfo!).takeUnretainedValue()
		let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as! [String]

		for index in (0 ..< numEvents).indices {
			try? fileSystemWatcher.callback?(FileWatcherEvent(eventIds[index], paths[index], eventFlags[index]))
		}
	}

	let retainCallback: CFAllocatorRetainCallBack = { (info: UnsafeRawPointer?) in
		_ = Unmanaged<FileWatcher>.fromOpaque(info!).retain()
		return info
	}

	let releaseCallback: CFAllocatorReleaseCallBack = { (info: UnsafeRawPointer?) in
		Unmanaged<FileWatcher>.fromOpaque(info!).release()
	}

	func selectStreamScheduler() {
		if let queue = queue {
			FSEventStreamSetDispatchQueue(streamRef!, queue)
		} else {
			FSEventStreamSetDispatchQueue(streamRef!, DispatchQueue.main)
		}
	}
}

/**
 * Convenient
 */
extension FileWatcher {
	convenience init(
		_ paths: [String],
		_ callback: @escaping CallBack,
		_ queue: DispatchQueue
	) {
		self.init(paths)
		self.callback = callback
		self.queue = queue
	}

	func start() {
		guard !hasStarted else { return } // -- make sure we are not already listening!
		var context = FSEventStreamContext(
			version: 0,
			info: Unmanaged.passUnretained(self).toOpaque(),
			retain: retainCallback,
			release: releaseCallback,
			copyDescription: nil
		)
		streamRef = FSEventStreamCreate(
			kCFAllocatorDefault,
			eventCallback,
			&context,
			filePaths as CFArray,
			FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
			0,
			UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
		)
		selectStreamScheduler()
		FSEventStreamStart(streamRef!)
	}
}

//
// aus der Technik, on 16.05.23.
// https://www.ausdertechnik.de
//
// Based on: https://github.com/eonist/FileWatcher/tree/master
//

import Foundation

#if os(macOS)
	/**
	 * - Parameters:
	 *    - id: is an id number that the os uses to differentiate between events.
	 *    - path: is the path the change took place. its formatted like so: Users/John/Desktop/test/text.txt
	 *    - flag: pertains to the file event type.
	 * ## Examples:
	 * let url = NSURL(fileURLWithPath: event.path)//<--formats paths to: file:///Users/John/Desktop/test/text.txt
	 * Swift.print("fileWatcherEvent.fileChange: " + "\(event.fileChange)")
	 * Swift.print("fileWatcherEvent.fileModified: " + "\(event.fileModified)")
	 * Swift.print("\t eventId: \(event.id) - eventFlags:  \(event.flags) - eventPath:  \(event.path)")
	 */
	public class FileWatcherEvent {
		public var id: FSEventStreamEventId
		public var path: String
		public var flags: FSEventStreamEventFlags

		init(_ eventId: FSEventStreamEventId, _ eventPath: String, _ eventFlags: FSEventStreamEventFlags) {
			self.id = eventId
			self.path = eventPath
			self.flags = eventFlags
		}
	}

	/**
	 * The following code is to differentiate between the FSEvent flag types (aka file event types)
	 * - Remark: Be aware that .DS_STORE changes frequently when other files change
	 */
	extension FileWatcherEvent {
		// General
		var fileChange: Bool { (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsFile)) != 0 }
		var dirChange: Bool { (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsDir)) != 0 }
		// CRUD
		var created: Bool { (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated)) != 0 }
		var removed: Bool { (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRemoved)) != 0 }
		var renamed: Bool { (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed)) != 0 }
		var modified: Bool { (flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified)) != 0 }
	}

	/**
	 * Convenience
	 */
	public extension FileWatcherEvent {
		// File
		var fileCreated: Bool { fileChange && created }
		var fileRemoved: Bool { fileChange && removed }
		var fileRenamed: Bool { fileChange && renamed }
		var fileModified: Bool { fileChange && modified }
		// Directory
		var dirCreated: Bool { dirChange && created }
		var dirRemoved: Bool { dirChange && removed }
		var dirRenamed: Bool { dirChange && renamed }
		var dirModified: Bool { dirChange && modified }
	}

	/**
	 * Simplifies debugging
	 * ## Examples:
	 * Swift.print(event.description) // Outputs: The file /Users/John/Desktop/test/text.txt was modified
	 */
	public extension FileWatcherEvent {
		var description: String {
			var result = "The \(fileChange ? "file" : "directory") \(path) was"
			if removed { result += " removed" }
			else if created { result += " created" }
			else if renamed { result += " renamed" }
			else if modified { result += " modified" }
			return result
		}
	}
#endif

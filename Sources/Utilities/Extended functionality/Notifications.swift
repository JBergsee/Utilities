//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-11-01.
//

import Foundation


public extension Notification.Name {
    
    /*
     Now when you want to post a notification with no details, which is the most common usage, you just do:
     Notification.Name.NOTIFICATIONSOMETHINGHAPPENED.post()
     
     And to "catch" it you just do:
     Notification.Name.NOTIFICATIONSOMETHINGHAPPENED.onPost { [weak self] note in
         guard let `self` = self else { return }
         // Do your stuff here
     }
     
     */
    
    //Example of how to define notification names
    static let NOTIFICATIONSOMETHINGHAPPENED = Notification.Name("Something Happened")
    
    /// Posts the notification
    func post(object: Any? = nil, userInfo: [AnyHashable : Any]? = nil) {
        NotificationCenter.default.post(name: self, object: object, userInfo: userInfo)
    }
    
    /**
     Convenience method for NotificationCenter that assumes the task of wrapping the observation token for us:
     Returns a custom NotificationToken that must be stored in a local variable in order to provide automatic deregistering.
     See https://oleb.net/blog/2018/01/notificationcenter-removeobserver/
     
     Furthermore, the block provided must capture self weakly, as so:
     ```
     token = Notification.Name.NOTIFICATIONSOMETHINGHAPPENED.onPost { [weak self] note in
         guard let self = self else { return }
         // Do your stuff here
     }
     ```
     */
    func onPost(object: Any? = nil, queue: OperationQueue? = nil, using: @escaping (Notification) -> Void) -> NotificationToken {
        let token = NotificationCenter.default.addObserver(forName: self, object: object, queue: queue, using: using)
        return NotificationToken(token: token)
    }
}



/// Wraps the observer token received from
/// NotificationCenter.addObserver(forName:object:queue:using:)
/// and unregisters it in deinit.
public final class NotificationToken: NSObject {
    let notificationCenter: NotificationCenter
    let token: Any

    init(notificationCenter: NotificationCenter = .default, token: Any) {
        self.notificationCenter = notificationCenter
        self.token = token
    }

    deinit {
        notificationCenter.removeObserver(token)
    }
}


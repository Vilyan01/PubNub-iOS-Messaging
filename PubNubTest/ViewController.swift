//
//  ViewController.swift
//  PubNubTest
//
//  Created by Brian Heller on 10/25/15.
//  Copyright © 2015 Reaper Sofware Solution. All rights reserved.
//

import UIKit
import PubNub
import JSQMessagesViewController
import Parse

class ViewController: JSQMessagesViewController {
    
    let config = PNConfiguration(publishKey: "YOUR_PUBNUB_PUBLIH_KEY", subscribeKey: "YOUR_PUBNUB_SUBCRIBE_KEY")
    var client:PubNub?
    
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor(red: 10/255, green: 180/255, blue: 230/255, alpha: 1.0))
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.lightGrayColor())
    var messages = [JSQMessage]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

// #MARK - PubNub

extension ViewController : PNObjectEventListener {
    func setup() {
        self.client = PubNub.clientWithConfiguration(self.config)
        self.client?.addListener(self)
        self.client?.subscribeToChannels(["test"], withPresence: false)
        self.senderId = UIDevice.currentDevice().identifierForVendor?.UUIDString
        self.senderDisplayName = UIDevice.currentDevice().identifierForVendor?.UUIDString
        self.loadMessagesFromParse()
    }
    
    func publishMessageToChannel(message:JSQMessage) {
        self.client?.publish(message.text, toChannel: "test", compressed: false, withCompletion: nil)
    }
    
    func client(client: PubNub!, didReceiveMessage message: PNMessageResult!) {
        /*
            Note:
            This is hardcoded as another user right now, in the future you will want to find a way to figure out who the sender actually is.  I have already done this on my other project so if you want to wait a few days I'll update it with how I did it, but it's already 12:30 AM and I is tired from trying to figure this out all day so deal with it.
        */
        let msg = JSQMessage(senderId: "test", displayName: "test", text: message.data.message as! String)
        self.messages.append(msg)
        self.finishReceivingMessage()
    }
}

//MARK - Data Source
extension ViewController {
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        let data = self.messages[indexPath.row]
        return data
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, didDeleteMessageAtIndexPath indexPath: NSIndexPath!) {
        self.messages.removeAtIndex(indexPath.row)
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        switch(data.senderId) {
        case self.senderId:
            return self.outgoingBubble
        default:
            return self.incomingBubble
        }
    }
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
}
//MARK - Toolbar
extension ViewController {
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        let message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        self.messages += [message]
        self.publishMessageToChannel(message)
        self.saveMessageToParse(message)
        self.finishSendingMessage()
    }
    override func didPressAccessoryButton(sender: UIButton!) {
    }
}


// MARK - Parse
extension ViewController {
    func loadMessagesFromParse() {
        let query = PFQuery(className: "test")
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if(error != nil) {
                NSLog("Error getting messages: %@",(error?.localizedDescription)!)
                return
            }
            if let objects = objects {
                for message in objects {
                    let jsqMessage = JSQMessage(senderId: message["senderId"] as! String, displayName: message["senderDisplayName"] as! String, text: message["body"] as! String)
                    self.messages.append(jsqMessage)
                }
            }
            self.collectionView?.reloadData()
        }
    }
    
    func saveMessageToParse(message:JSQMessage) {
        let msg = PFObject(className: "test")
        msg["senderId"] = message.senderId
        msg["body"] = message.text
        msg["senderDisplayName"] = message.senderDisplayName
        msg.saveInBackgroundWithBlock { (success, error) -> Void in
            if(error != nil) {
               NSLog("error: %@",(error?.localizedDescription)!)
            }
        }
    }
}


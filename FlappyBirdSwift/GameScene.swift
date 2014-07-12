//
//  GameScene.swift
//  FlappyBirdSwift
//
//  Created by Rafal Szymanski on 7/3/14.
//  Copyright (c) 2014 rafalio. All rights reserved.
//

import SpriteKit

let playerCategory:UInt32 = 1
let groundCategory:UInt32 = 2
let pipeCategory:UInt32   = 4

let pipeVSpacing:CGFloat = 130
let pipeHSpacing:CGFloat = 150
let pipeWidth:CGFloat    = 30

enum GameState{
    case Waiting
    case Playing
    case DeathScreen
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player:SKNode!
    var score:Int = 0
    var gameOverLabel:SKLabelNode!
    var scoreLabel:SKLabelNode!
    
    
    var appState:GameState = .Waiting{
        didSet{
            if(appState == .Waiting){
                resetPlayerPosition()
                self.paused = true
            }
            else if(appState == .Playing){
                self.paused = false
            }
            else if(appState == .DeathScreen){
                // nothing
            }
            updateUI()
        }
    }
    
    
    override func didMoveToView(view: SKView) {
        println("Width: \(view.frame.size.width), height: \(view.frame.size.height)")
        self.backgroundColor = UIColor.whiteColor()
        self.anchorPoint = CGPointMake(0.5,0.5);
        self.paused = true // pause the scene
        self.physicsWorld.contactDelegate = self
        
        let pSize:CGFloat = 30
        player = SKSpriteNode(color:UIColor.blackColor(), size:CGSizeMake(pSize, pSize))
        resetPlayerPosition()
        
        player.physicsBody = SKPhysicsBody(rectangleOfSize:CGSizeMake(pSize,pSize));
        player.physicsBody.categoryBitMask    = playerCategory
        player.physicsBody.contactTestBitMask = groundCategory
        player.physicsBody.collisionBitMask   = groundCategory
        self.addChild(player)
        
        // The base that doesn't take part in the physics simulation
        let base = SKSpriteNode(color:UIColor.brownColor(), size: CGSizeMake(view.frame.size.width, 100))
        base.position = CGPointMake(0,-CGRectGetMidY(view.frame)+base.size.height/2)
        self.addChild(base)
        
        
        let ground = SKSpriteNode(color:UIColor.blueColor(), size: CGSizeMake(view.frame.size.width, 10))
        ground.position = CGPointMake(0,base.position.y + base.size.height/2)
        
        ground.physicsBody = SKPhysicsBody(rectangleOfSize:ground.size)
        ground.physicsBody.categoryBitMask = groundCategory
        ground.physicsBody.contactTestBitMask = playerCategory
        ground.physicsBody.collisionBitMask = 0
        ground.physicsBody.affectedByGravity = false
        self.addChild(ground)
        
        setUpLabels()
        
        var p = getPipe()
        
        
        self.addChild(p)
        
    }
    
    override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
        if(appState == .Waiting){
            appState = .Playing
            thrustBird()
        }
        else if(appState == .Playing){  // apply a force to move the bird
            thrustBird()
        }
        else if(appState == .DeathScreen){ // go back to waiting screen
            appState = .Waiting
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact!){
        if(appState != .DeathScreen){
            appState = .DeathScreen
        }
    }
    
    func thrustBird(){
        player.physicsBody.velocity = CGVectorMake(0, 0)
        player.physicsBody.applyImpulse(CGVectorMake(0, 19))
    }
    
    func updateUI(){
        if(appState == .DeathScreen){
            self.addChild(gameOverLabel)
            scoreLabel.text = "\(score)"
            self.addChild(scoreLabel)
        }
        else{
            gameOverLabel.removeFromParent()
            scoreLabel.removeFromParent()
        }
    }
    
    func resetPlayerPosition(){
        player.position = CGPointMake(-60,0)
    }
    
    func setUpLabels(){
        gameOverLabel = SKLabelNode(fontNamed:"Avenir")
        gameOverLabel.text = "Game Over"
        gameOverLabel.fontSize = 25
        gameOverLabel.position = CGPointMake(0,0)
        gameOverLabel.fontColor = UIColor.blackColor()
        
        scoreLabel = SKLabelNode(fontNamed:"Avenir")
        scoreLabel.fontSize = 25
        scoreLabel.position = CGPointMake(0,-30)
        scoreLabel.fontColor = UIColor.blackColor()
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    // returns an SKNode with the top and bottom pipe
    func getPipe() -> SKNode{
        let holeStartY = CGFloat((arc4random() % 200) + 200)
        let pipeStartY:CGFloat = 110
        
        let bottomPieceHeight = holeStartY - pipeStartY
        let topPieceHeight:CGFloat = 500 // make the piece on top extend beyond the top of the screen for the bird to crash
        
        let bottomPiece = SKSpriteNode(color: UIColor.blackColor(), size: CGSizeMake(pipeWidth, bottomPieceHeight))
        bottomPiece.position = CGPointMake(0, 0)
        bottomPiece.color = UIColor.redColor()
        
        let topPiece = SKSpriteNode(color: UIColor.blackColor(), size: CGSizeMake(pipeWidth, topPieceHeight))
        topPiece.position = CGPointMake(0,topPiece.size.height/2 + pipeVSpacing + bottomPieceHeight/2)
        
        let node = SKNode()
        node.addChild(topPiece)
        node.addChild(bottomPiece)
        
        
        return node
    }
    
    
}

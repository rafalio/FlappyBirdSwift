//
//  GameScene.swift
//  FlappyBirdSwift
//
//  Created by Rafal Szymanski on 7/12/14.
//  Copyright (c) 2014 rafalio. All rights reserved.
//

import SpriteKit

let playerCategory:UInt32 = 1
let groundCategory:UInt32 = 2
let pipeCategory:UInt32   = 4

let pipeVSpacing:CGFloat = 120
let pipeHSpacing:CGFloat = 150
let pipeWidth:CGFloat    = 30

enum GameState{
    case Waiting
    case Playing
    case DeathScreen
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player:SKNode!
    var score:Int = 0 {
        didSet{
            scoreLabel.text = "\(score)"
        }
    }
    var gameOverLabel:SKLabelNode!
    var scoreLabel:SKLabelNode!
    var pipeAccum:Array<SKNode> = []
    
    var appState:GameState = .Waiting{
        didSet{
            if(appState == .Waiting){
                gameOverLabel.removeFromParent()
                resetLevel()
                self.paused = true
            }
            else if(appState == .Playing){
                self.paused = false
                spawnPipes()
            }
            else if(appState == .DeathScreen){
                self.addChild(gameOverLabel)
                self.paused = true
            }
        }
    }
    
    
    override func didMoveToView(view: SKView) {
        println("Width: \(view.frame.size.width), height: \(view.frame.size.height)")
        self.backgroundColor = UIColor.whiteColor()
        self.paused = true // pause the scene
        self.physicsWorld.contactDelegate = self
        setUpLabels()
        
        let pSize:CGFloat = 20
        player = SKSpriteNode(color:UIColor.blackColor(), size:CGSizeMake(pSize, pSize))
        resetLevel()
        
        player.physicsBody = SKPhysicsBody(rectangleOfSize:CGSizeMake(pSize,pSize));
        player.physicsBody.categoryBitMask    = playerCategory
        player.physicsBody.contactTestBitMask = groundCategory
        player.physicsBody.collisionBitMask   = groundCategory
        player.physicsBody.mass = 2
        player.physicsBody.allowsRotation = false
        
        self.addChild(player)
        
        // The base that doesn't take part in the physics simulation
        let base = SKSpriteNode(color:UIColor.brownColor(), size: CGSizeMake(view.frame.size.width, 100))
        base.position = CGPointMake(view.frame.width/2,base.size.height/2)
        self.addChild(base)
        
        let ground = SKSpriteNode(color:UIColor.blueColor(), size: CGSizeMake(view.frame.size.width, 10))
        ground.position = CGPointMake(view.frame.width/2, base.position.y + base.size.height/2 + ground.size.height/2)
        
        ground.physicsBody = SKPhysicsBody(rectangleOfSize:ground.size)
        ground.physicsBody.categoryBitMask = groundCategory
        ground.physicsBody.contactTestBitMask = playerCategory
        ground.physicsBody.collisionBitMask = 0
        ground.physicsBody.affectedByGravity = false
        self.addChild(ground)
        
        
        self.addChild(scoreLabel)
    }
    
    func spawnPipes(){
        if(appState == .Playing){
            let pipes = getPipe()
            pipes.position = CGPoint(x: view.frame.width + 30, y: pipes.position.y)
            self.addChild(pipes)
            pipeAccum.append(pipes)
            
            let velocity:Double = 130 // pixels per second
            let dist:Double     = Double(view.frame.size.width)
            let time            = dist/velocity
            let sucDist:Double  = 130 // distance between succesive pipes
            let waitTime:Double = sucDist/velocity
            
            let animAction = SKAction.sequence([
                SKAction.moveToX(player.position.x, duration: (pipes.position.x-player.position.x)/velocity),
                SKAction.runBlock({ () in self.score++; return () }),
                SKAction.moveToX(-pipeWidth, duration: (player.position.x+pipeWidth)/velocity)
                ])
            let doneAction = SKAction.sequence([SKAction.removeFromParent(), SKAction.runBlock({() in
                self.pipeAccum.removeAtIndex(0) // inefficient, ideally this should be a queue, but... well swift doesn't have one
                return ()
                })])
            let recurse    = SKAction.runBlock({
                self.spawnPipes()
            })
            let compoundAction = SKAction.sequence([SKAction.waitForDuration(waitTime), recurse, animAction, doneAction])
            pipes.runAction(compoundAction)
        }
        
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
        if(appState != .DeathScreen){ // any kind of touch makes the player die
            appState = .DeathScreen
        }
    }
    
    func thrustBird(){
        player.physicsBody.velocity = CGVectorMake(0, 0)
        player.physicsBody.applyImpulse(CGVectorMake(0, 800))
    }
    
    
    func resetLevel(){
        player.position = CGPointMake(view.frame.width/2 - 50, view.frame.height/2)
        for p in pipeAccum{
            p.removeFromParent()
        }
        pipeAccum.removeAll(keepCapacity: true)
        score = 0
    }
    
    func setUpLabels(){
        gameOverLabel = SKLabelNode(fontNamed:"Avenir")
        gameOverLabel.text = "Game Over"
        gameOverLabel.fontSize = 25
        gameOverLabel.position = CGPointMake(view.frame.width/2,view.frame.height/2)
        gameOverLabel.fontColor = UIColor.blackColor()
        
        scoreLabel = SKLabelNode(fontNamed:"Avenir")
        scoreLabel.fontSize = 25
        scoreLabel.position = CGPointMake(view.frame.width/2,view.frame.height/2-30)
        scoreLabel.fontColor = UIColor.blackColor()
        
    }
    
    // returns an SKNode with the top and bottom pipe
    func getPipe() -> SKNode{
        
        func addPipePhysics(pipe: SKSpriteNode){
            pipe.physicsBody = SKPhysicsBody(rectangleOfSize:pipe.size)
            pipe.physicsBody.categoryBitMask = pipeCategory
            pipe.physicsBody.contactTestBitMask = playerCategory
            pipe.physicsBody.collisionBitMask = 0
            pipe.physicsBody.affectedByGravity = false
        }
        
        let holeStartY = CGFloat((arc4random() % 200) + 200)
        let pipeStartY:CGFloat = 110
        
        let bottomPieceHeight = holeStartY - pipeStartY
        let topPieceHeight:CGFloat = 500 // make the piece on top extend beyond the top of the screen for the bird to crash
        
        let bottomPiece = SKSpriteNode(color: UIColor.blackColor(), size: CGSizeMake(pipeWidth, bottomPieceHeight))
        bottomPiece.position = CGPointMake(pipeWidth/2, bottomPieceHeight/2 + 110)
        bottomPiece.color = UIColor.redColor()
        addPipePhysics(bottomPiece)
        
        let topPiece = SKSpriteNode(color: UIColor.blackColor(), size: CGSizeMake(pipeWidth, topPieceHeight))
        topPiece.position = CGPointMake(pipeWidth/2, bottomPiece.position.y + bottomPiece.size.height/2 + pipeVSpacing + topPieceHeight/2)
        addPipePhysics(topPiece)
        
        let node = SKNode()
        node.addChild(topPiece)
        node.addChild(bottomPiece)
        
        return node
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
    
}

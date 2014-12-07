import SpriteKit

enum Layers : CGFloat {
	case World = 5.0
	case Resource = 8.0
	case Spawner = 10.0
}

class Spawner : SKNode {
	var spawnAction : SKAction?
	let looks : SKShapeNode
	
	init(p: CGPoint) {
		looks = SKShapeNode(rectOfSize: CGSizeMake(40, 40))
		looks.fillColor = SKColor.blueColor()
		super.init()
		self.position = p
		self.addChild(looks)
		self.zPosition = Layers.Spawner.rawValue
		start()
	}
	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	func start() {
		spawnAction = SKAction.repeatActionForever(SKAction.sequence([
			SKAction.runBlock({ () -> Void in
				let resource = Resource()
				resource.position = self.position
				self.parent!.addChild(resource)
			}),
			SKAction.waitForDuration(1),
		]))
		self.runAction(spawnAction)
	}
}

class Resource : SKNode {
	let looks : SKShapeNode

	override init() {
		looks = SKShapeNode(rectOfSize: CGSizeMake(10, 20))
		looks.fillColor = SKColor.greenColor()
		super.init()
		self.addChild(looks)
		self.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(10, 20))
		self.physicsBody!.friction = 1.0
		self.zPosition = Layers.Resource.rawValue
	}
	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}

class Conveyor : SKNode {
	let looks : SKShapeNode
	init(p: CGPoint) {
		looks = SKShapeNode(circleOfRadius: 20)
		looks.fillColor = SKColor.grayColor()
		let line = SKShapeNode(rect: CGRectMake(0, 0, 20, 1))
		line.fillColor = SKColor.lightGrayColor()
		looks.addChild(line)
		super.init()
		self.position = p
		self.addChild(looks)
		self.physicsBody = SKPhysicsBody(circleOfRadius: 20)
		self.physicsBody!.affectedByGravity = false
		self.physicsBody!.mass = 1000000
		self.physicsBody!.friction = 1.0
		self.zPosition = Layers.World.rawValue
		
		self.runAction(SKAction.repeatActionForever(SKAction.sequence([
			SKAction.runBlock({ () -> Void in
				self.physicsBody!.angularVelocity = -10
			}),
			SKAction.waitForDuration(0.5),
		])))
	}
	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}

}

class GameScene: SKScene {
    override func didMoveToView(view: SKView) {
		addChild(Spawner(p: CGPointMake(200, 200)))
    }
    
    override func mouseDown(theEvent: NSEvent) {
		addConveyor(atPoint: theEvent.locationInNode(self))

    }
	
	func addConveyor(#atPoint: CGPoint) {
		addChild(Conveyor(p: atPoint))
	}
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}

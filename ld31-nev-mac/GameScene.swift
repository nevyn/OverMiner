import SpriteKit

enum Layers : CGFloat {
	case World = 5.0
	case Resource = 8.0
	case Spawner = 10.0
}


class Extractor : SKNode {
	let looks : SKShapeNode
	var totalValue: Int
	let valuePerResource: Int
	
	class func makeLooks() -> SKShapeNode {
		let looks = SKShapeNode(rectOfSize: CGSizeMake(40, 40))
		looks.fillColor = SKColor.blueColor()
		return looks
	}
	
	init(p: CGPoint, totalValue: Int, valuePerResource: Int) {
		looks = Extractor.makeLooks()
		self.totalValue = totalValue
		self.valuePerResource = valuePerResource
		super.init()
		self.addChild(looks)
		self.position = p
		self.zPosition = Layers.Spawner.rawValue
		start()
	}
	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
	func start() {
		let spawnAction = SKAction.repeatActionForever(SKAction.sequence([
			SKAction.runBlock({ () -> Void in
				let newValue = self.totalValue - self.valuePerResource
				if newValue > 0 {
					self.totalValue = newValue
					let resource = Resource(value: self.valuePerResource)
					resource.position = self.position
					self.parent!.addChild(resource)
				} else {
					self.looks.fillColor = SKColor.redColor()
					self.removeActionForKey("spawn")
				}
			}),
			SKAction.waitForDuration(1),
		]))
		self.runAction(spawnAction, withKey: "spawn")
	}
}

class Resource : SKNode {
	let looks : SKShapeNode
	let value : Int

	init(value: Int) {
		looks = SKShapeNode(rectOfSize: CGSizeMake(10, 20))
		looks.fillColor = SKColor.greenColor()
		self.value = value
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
	class func makeLooks() -> SKShapeNode {
		let looks = SKShapeNode(circleOfRadius: 20)
		looks.fillColor = SKColor.grayColor()
		let line = SKShapeNode(rect: CGRectMake(0, 0, 20, 1))
		line.fillColor = SKColor.lightGrayColor()
		looks.addChild(line)
		return looks
	}
	init(p: CGPoint) {
		looks = Conveyor.makeLooks()
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

class Tool : SKNode {
	let border = SKShapeNode(rectOfSize: CGSizeMake(46, 46))
	override init() {
		super.init()
		border.fillColor = SKColor.clearColor()
		self.addChild(border)
	}
	required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
	
	
	func perform(game: GameScene, at: CGPoint) {
	
	}
}

class BuildExtractorTool : Tool {
	let looks : SKShapeNode
	override init() {
		looks = Extractor.makeLooks()
		super.init()
		looks.position = CGPointMake(3, 3)
		self.addChild(looks)
	}
	required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
	
	override func perform(game: GameScene, at: CGPoint) {
		if game.buy(50) {
			game.addChild(Extractor(p: at, totalValue: 1000, valuePerResource: 10))
		}
	}
}

class BuyConveyorTool : Tool {
	let looks : SKShapeNode
	override init() {
		looks = Conveyor.makeLooks()
		super.init()
		looks.position = CGPointMake(3, 3)
		self.addChild(looks)
	}
	required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

	override func perform(game: GameScene, at: CGPoint) {
		if game.buy(10) {
			game.addChild(Conveyor(p:at))
		}
	}
}

class Toolbar : SKNode {
	var tools : [Tool] = []
	let game: GameScene
	init(game: GameScene) {
		self.game = game
		super.init()
		tools = [
			BuildExtractorTool(),
			BuyConveyorTool(),
		]
		var pen = CGPointMake(0, 0)
		for tool in tools {
			addChild(tool)
			tool.position = pen
			pen.y -= 40
		}
	}
	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
}

class GameScene: SKScene {
	var resources = 100
	func buy(cost: Int) -> Bool {
		if resources - cost > 0 {
			resources -= cost
			return true
		} else {
			return false
		}
	}
	
	var toolbar: Toolbar!
	
    override func didMoveToView(view: SKView) {
		toolbar = Toolbar(game: self)
		toolbar.position = CGPointMake(30, self.size.height-30)
		addChild(toolbar)
    }
    
    override func mouseDown(theEvent: NSEvent) {


    }
	
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}

import SpriteKit

enum Layers : CGFloat {
	case Background = 0.0
	case World = 5.0
	case Resource = 8.0
	case Spawner = 10.0
	case UI = 100.0
}

enum Tileset : UInt {
	case Empty = 1
	case SoftSand
	case HardSand
	case Stone
	case Mineral
	case Exit
}

enum Categories : UInt32 {
	case Resource = 1
	case Exit = 2
}

let kGridSize = CGFloat(40.0)


class Extractor : SKNode {
	let looks : SKShapeNode
	var totalValue: Int
	let valuePerResource: Int
	
	class func makeLooks() -> SKShapeNode {
		let looks = SKShapeNode(rectOfSize: CGSizeMake(kGridSize, kGridSize))
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
		looks = SKShapeNode(rectOfSize: CGSizeMake(kGridSize/4, kGridSize/2))
		looks.fillColor = SKColor.greenColor()
		self.value = value
		super.init()
		self.addChild(looks)
		self.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(kGridSize/4, kGridSize/2))
		self.physicsBody!.friction = 1.0
		self.physicsBody!.categoryBitMask = Categories.Resource.rawValue
		self.zPosition = Layers.Resource.rawValue
	}
	required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

class Exit : SKNode {
	let looks: SKShapeNode
	
	class func makeLooks() -> SKShapeNode {
		let looks = SKShapeNode(circleOfRadius: kGridSize/2)
		looks.fillColor = SKColor.blackColor()
		return looks
	}
	
	override init() {
		looks = Exit.makeLooks()
		super.init()
		self.addChild(looks)
		self.physicsBody = SKPhysicsBody(circleOfRadius: kGridSize/2)
		self.physicsBody!.affectedByGravity = false
		self.physicsBody!.mass = 1000000
		self.physicsBody!.categoryBitMask = Categories.Exit.rawValue
		self.physicsBody!.contactTestBitMask = Categories.Resource.rawValue
		self.zPosition = Layers.World.rawValue
	}
	required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

class Conveyor : SKNode {
	let looks : SKShapeNode
	class func makeLooks() -> SKShapeNode {
		let looks = SKShapeNode(circleOfRadius: kGridSize/2)
		looks.fillColor = SKColor.grayColor()
		let line = SKShapeNode(rect: CGRectMake(0, 0, kGridSize/2, 1))
		line.fillColor = SKColor.lightGrayColor()
		looks.addChild(line)
		return looks
	}
	init(p: CGPoint) {
		looks = Conveyor.makeLooks()
		super.init()
		self.position = p
		self.addChild(looks)
		self.physicsBody = SKPhysicsBody(circleOfRadius: kGridSize/2)
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

class SoftSand : SKSpriteNode {
	convenience init(p: CGPoint) {
		self.init(imageNamed: "soft_sand")
		self.position = p
	}
}

class HardSand : SKSpriteNode {
	convenience init(p: CGPoint) {
		self.init(imageNamed: "hard_sand")
		self.position = p
	}
}

class Stone : SKSpriteNode {
	convenience init(p: CGPoint) {
		self.init(imageNamed: "stone")
		self.position = p
	}
}

class Level : SKNode {
	let looks : SKShapeNode
	init(name: String) {
		let levelData = NSData(contentsOfURL: NSBundle.mainBundle().URLForResource(name, withExtension: "json")!)!
		let object = NSJSONSerialization.JSONObjectWithData(levelData, options: NSJSONReadingOptions(0), error: nil) as NSDictionary
		let w = object["width"] as Int
		let h = object["height"] as Int
		let pixelSize = CGSizeMake(CGFloat(w)*kGridSize, CGFloat(h)*kGridSize)
		looks = SKShapeNode(rectOfSize: pixelSize)
		looks.fillColor = SKColor.lightGrayColor()
		looks.zPosition = Layers.Background.rawValue
		super.init()
		self.addChild(looks)
		
		let layers = object["layers"] as NSArray
		let firstLayer = layers[0] as NSDictionary
		let layerData = firstLayer["data"] as [UInt]
		var linearPosition = 0
		for datum in layerData {
			var p = CGPointMake(CGFloat(linearPosition % w), CGFloat(linearPosition/w))
			p.x -= CGFloat(w)/2
			p.y -= CGFloat(h)/2
			p = p * kGridSize
			
			var tile : SKNode!
			switch Tileset(rawValue:datum)! {
				case .SoftSand:
					tile = SoftSand(p: p)
				case .HardSand:
					tile = HardSand(p: p)
				case .Stone:
					tile = Stone(p: p)
				case .Mineral:
					tile = Resource(value: 500)
					tile.position = p
				case .Exit:
					tile = Exit()
					tile.position = p
				default: // ignore
					break
			}
			addChild(tile)
			linearPosition += 1
		}
	}
	required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

class Tool : SKNode {
	let border = SKShapeNode(rectOfSize: CGSizeMake(kGridSize + 8, kGridSize + 8))
	var active : Bool = false {
		didSet {
			border.strokeColor = active ? SKColor.magentaColor() : SKColor.whiteColor()
		}
	}
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
		self.addChild(looks)
	}
	required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
	
	override func perform(game: GameScene, at: CGPoint) {
		if game.buy(50) {
			game.level.addChild(Extractor(p: at, totalValue: 1000, valuePerResource: 10))
		}
	}
}

class BuyConveyorTool : Tool {
	let looks : SKShapeNode
	override init() {
		looks = Conveyor.makeLooks()
		super.init()
		self.addChild(looks)
	}
	required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

	override func perform(game: GameScene, at: CGPoint) {
		if /*game.level.nodeAtPoint(at) == game.level &&*/ game.buy(10) {
			game.level.addChild(Conveyor(p:at))
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
		tools[0].active = true
		var pen = CGPointMake(0, 0)
		for tool in tools {
			addChild(tool)
			tool.position = pen
			pen.x += kGridSize + 9
		}
	}
	func activeTool() -> Tool {
		for tool in tools {
			if tool.active == true {
				return tool
			}
		}
		fatalError("must be an active tool")
	}
	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
	
    func toolbarClick(p: CGPoint) {
		for node in self.nodesAtPoint(p) {
			if let tool = node as? Tool {
				activeTool().active = false
				tool.active = true
			}
		}
	}
	
}

class GameScene: SKScene, SKPhysicsContactDelegate {
	var resources : Int = 200 {
		didSet {
			resourceLabel.text = "\(resources)"
		}
	}
	func buy(cost: Int) -> Bool {
		if resources - cost >= 0 {
			resources -= cost
			return true
		} else {
			return false
		}
	}
	
	var toolbar: Toolbar!
	let resourceLabel = SKLabelNode(fontNamed: "Superclarendon-Regular")
	
	var level : Level!
	
    override func didMoveToView(view: SKView) {
		
		self.backgroundColor = SKColor.blackColor()
		
		level = Level(name: "levels/level_1")
		level.position = CGPointMake(self.size.width/2, self.size.height/2 - 0.5*kGridSize)
		addChild(level)
		
		toolbar = Toolbar(game: self)
		toolbar.position = CGPointMake(kGridSize/2+10, self.size.height-kGridSize/2-10)
		addChild(toolbar)
		
		resourceLabel.position = CGPointMake(self.size.width - 50, self.size.height - 30)
		resourceLabel.fontSize = 20
		addChild(resourceLabel)
		buy(0)
		
		self.physicsWorld.contactDelegate = self
    }
    
    override func mouseDown(theEvent: NSEvent) {
		let pointInGame = theEvent.locationInNode(self)
		for node in self.nodesAtPoint(pointInGame) as [SKNode] {
			if let toolbar = node as? Toolbar {
				toolbar.toolbarClick(theEvent.locationInNode(toolbar))
				return
			} else if node == level {
				var pointInLevel = theEvent.locationInNode(self.level)
				pointInLevel.x += (pointInLevel.x > 0) ? (kGridSize/2.0) : -(kGridSize/2.0)
				pointInLevel.y += (pointInLevel.y > 0) ? (kGridSize/2.0) : -(kGridSize/2.0)
				
				let intGridSize = Int(kGridSize)
				let gridCoordinate = CGPointMake(CGFloat(Int((pointInLevel.x)/kGridSize)), CGFloat(Int((pointInLevel.y)/kGridSize)))
				let pointAlignedOnGrid = gridCoordinate*kGridSize
				
				println("point: \(pointInLevel) grid coordinate: \(gridCoordinate), point: \(pointAlignedOnGrid)")
				
				toolbar.activeTool().perform(self, at: pointAlignedOnGrid)
			}
		}
		
    }
	
	func didBeginContact(contact: SKPhysicsContact) {
		if let resource = contact.bodyA.node as? Resource {
			if let exit = contact.bodyB.node as? Exit {
				resource.removeFromParent()
				resources += resource.value
			}
		}
	}

	
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}

func *(p: CGPoint, m: CGFloat) -> CGPoint {
	return CGPointMake(p.x*m, p.y*m)
}

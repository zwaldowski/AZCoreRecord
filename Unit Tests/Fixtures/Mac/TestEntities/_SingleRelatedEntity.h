// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SingleRelatedEntity.h instead.

#import <CoreData/CoreData.h>


extern const struct SingleRelatedEntityAttributes {
	__unsafe_unretained NSString *mappedStringAttribute;
} SingleRelatedEntityAttributes;

extern const struct SingleRelatedEntityRelationships {
	__unsafe_unretained NSString *testRelationship;
} SingleRelatedEntityRelationships;

extern const struct SingleRelatedEntityFetchedProperties {
} SingleRelatedEntityFetchedProperties;

@class ConcreteRelatedEntity;



@interface SingleRelatedEntityID : NSManagedObjectID {}
@end

@interface _SingleRelatedEntity : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SingleRelatedEntityID*)objectID;




@property (nonatomic, strong) NSString *mappedStringAttribute;


//- (BOOL)validateMappedStringAttribute:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) ConcreteRelatedEntity* testRelationship;

//- (BOOL)validateTestRelationship:(id*)value_ error:(NSError**)error_;




@end

@interface _SingleRelatedEntity (CoreDataGeneratedAccessors)

@end

@interface _SingleRelatedEntity (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveMappedStringAttribute;
- (void)setPrimitiveMappedStringAttribute:(NSString*)value;





- (ConcreteRelatedEntity*)primitiveTestRelationship;
- (void)setPrimitiveTestRelationship:(ConcreteRelatedEntity*)value;


@end

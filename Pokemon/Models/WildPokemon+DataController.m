//
//  WildPokemon+DataController.m
//  Pokemon
//
//  Created by Kaijie Yu on 2/27/12.
//  Copyright (c) 2012 Kjuly. All rights reserved.
//

#import "WildPokemon+DataController.h"

#import "PokemonServerAPI.h"
#import "AppDelegate.h"
#import "Pokemon+DataController.h"
#import "Move+DataController.h"

#import "AFJSONRequestOperation.h"

@implementation WildPokemon (DataController)

+ (BOOL)updateDataForCurrentRegion:(NSInteger)regionID
{
  // Success Block Method
  void (^blockPopulateData)(NSURLRequest *, NSHTTPURLResponse *, id) =
  ^(NSURLRequest * request, NSHTTPURLResponse * response, id JSON) {
    NSManagedObjectContext * managedObjectContext =
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    // Get JSON Data Array from HTTP Response
    NSArray * wildPokemons = [JSON valueForKey:@"wildpokemons"];
    
    NSError * error;
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([self class])
                                        inManagedObjectContext:managedObjectContext]];
    [fetchRequest setFetchLimit:1];
    
    // Update the data for |tamedPokemmon|
    for (NSDictionary * wildPokemonData in wildPokemons) {
      // Check the existence of the object
      [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"uid == %@", [wildPokemonData valueForKey:@"uid"]]];
      
      // If exist, execute fetching request, otherwise, insert new object
      WildPokemon * wildPokemon;
      if ([managedObjectContext countForFetchRequest:fetchRequest error:&error])
        wildPokemon = [[managedObjectContext executeFetchRequest:fetchRequest error:&error] lastObject];
      else {
        wildPokemon = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([self class])
                                                    inManagedObjectContext:managedObjectContext];
        // Set relationships
        Pokemon * pokemon = [Pokemon queryPokemonDataWithID:[[wildPokemonData valueForKey:@"sid"] intValue]];
        wildPokemon.pokemon = pokemon;
        pokemon = nil;
        
        NSArray * moveIDs = [[wildPokemonData valueForKey:@"fourMovesID"] componentsSeparatedByString:@","];
        NSArray * moves = [Move queryFourMovesDataWithIDs:moveIDs];
        [wildPokemon addFourMoves:[NSSet setWithArray:moves]];
        moves = nil;
        moveIDs = nil;
      }
      
      // Set data
      wildPokemon.uid         = [wildPokemonData valueForKey:@"uid"];
      wildPokemon.sid         = [wildPokemonData valueForKey:@"sid"];
      wildPokemon.status      = [wildPokemonData valueForKey:@"status"];
      wildPokemon.gender      = [wildPokemonData valueForKey:@"gender"];
      wildPokemon.level       = [wildPokemonData valueForKey:@"level"];
      wildPokemon.fourMovesPP = [wildPokemonData valueForKey:@"fourMovesPP"];
      wildPokemon.maxStats    = [wildPokemonData valueForKey:@"maxStats"];
      wildPokemon.currHP      = [wildPokemonData valueForKey:@"currHP"];
      wildPokemon.currEXP     = [wildPokemonData valueForKey:@"currEXP"];
      wildPokemon.toNextLevel = [wildPokemonData valueForKey:@"toNextLevel"];
    }
    
    [fetchRequest release];
    
    if (! [managedObjectContext save:&error])
      NSLog(@"!!! Couldn't save data to %@", NSStringFromClass([self class]));
#if DEBUG
    NSLog(@"...Update |%@| data done...", [self class]);
#endif
  };
  
  // Failure Block Method
  void (^blockError)(NSURLRequest *, NSHTTPURLResponse *, NSError *, id) =
  ^(NSURLRequest *request, NSHTTPURLResponse * response, NSError * error, id JSON) {
    NSLog(@"!!! ERROR: %@", error);
  };
  
  
  // Fetch data from server & populate the |teamedPokemon|
  NSURLRequest * request =
  [[NSURLRequest alloc] initWithURL:[PokemonServerAPI APIGetWildPokemonsForCurrentRegion:1]];
  
  AFJSONRequestOperation * operation =
  [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                  success:blockPopulateData
                                                  failure:blockError];
  [request release];
  [operation start];
  
  return true;
}

// Query a Wild Pokemon Data
+ (WildPokemon *)queryPokemonDataWithID:(NSInteger)pokemonID
{
  NSManagedObjectContext * managedObjectContext =
  [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
  NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
  NSEntityDescription * entity = [NSEntityDescription entityForName:NSStringFromClass([self class])
                                             inManagedObjectContext:managedObjectContext];
  [fetchRequest setEntity:entity];
  NSPredicate * predicate = [NSPredicate predicateWithFormat:@"sid == %d", pokemonID];
  [fetchRequest setPredicate:predicate];
  //  [fetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"", nil];
  [fetchRequest setFetchLimit:1];
  
  NSError * error;
  WildPokemon * pokemon = [[managedObjectContext executeFetchRequest:fetchRequest error:&error] lastObject];
  [fetchRequest release];
  
  return pokemon;
}

@end
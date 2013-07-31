package test.unit;

import def.*;

class TestUserCostModel extends TestCase {
	
	public function testUserCost() {
		var check = function ( u:UserCostModel, dist:Dist, time:Time, toll:Toll ):Void {
			var res:Float = u.userCost( dist, time, toll ); // casting def.Cost to Float
			assertPosInfinite( res ); // we don't want NaN results
			assertFalse( res < Math.POSITIVE_INFINITY ); // redundant with TestHaxe
			assertFalse( Math.POSITIVE_INFINITY > res ); // redundant with TestHaxe
		}

		var u = new UserCostModel( 1., .5, .5 );
		check( u, Math.POSITIVE_INFINITY, 0., 0. );
		check( u, 0., Math.POSITIVE_INFINITY, 0. );
		check( u, 0., 0., Math.POSITIVE_INFINITY );
		
		var u = new UserCostModel( 0., .5, .5 );
		check( u, Math.POSITIVE_INFINITY, 0., 0. );
		check( u, 0., Math.POSITIVE_INFINITY, 0. );
		check( u, 0., 0., Math.POSITIVE_INFINITY );

		var u = new UserCostModel( 1., 0., 0. );
		check( u, Math.POSITIVE_INFINITY, 0., 0. );
		check( u, 0., Math.POSITIVE_INFINITY, 0. );
		check( u, 0., 0., Math.POSITIVE_INFINITY );

		var u = new UserCostModel( 0., 0., 0. );
		check( u, Math.POSITIVE_INFINITY, 0., 0. );
		check( u, 0., Math.POSITIVE_INFINITY, 0. );
		check( u, 0., 0., Math.POSITIVE_INFINITY );
	}

}

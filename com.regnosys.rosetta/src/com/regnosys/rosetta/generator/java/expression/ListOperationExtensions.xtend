package com.regnosys.rosetta.generator.java.expression

import com.regnosys.rosetta.generator.java.function.CardinalityProvider
import com.regnosys.rosetta.generator.util.RosettaFunctionExtensions
import com.regnosys.rosetta.generator.util.Util
import com.regnosys.rosetta.rosetta.simple.ListOperation
import com.regnosys.rosetta.rosetta.simple.ListOperationKind
import com.regnosys.rosetta.types.RosettaTypeProvider
import javax.inject.Inject

import static extension com.regnosys.rosetta.generator.java.util.JavaClassTranslator.toJavaType

class ListOperationExtensions {
	
	
	@Inject protected RosettaTypeProvider typeProvider
	@Inject CardinalityProvider cardinalityProvider
	@Inject RosettaFunctionExtensions funcExt
	@Inject extension Util
	
	def String getInputRawType(ListOperation op) {
		typeProvider.getRType(op.receiver).name.toJavaType
	}
	
	def String getInputType(ListOperation op) {
		'''«IF funcExt.needsBuilder(op.receiver)»? extends «ENDIF»«op.inputRawType»'''
	}
	
	def String getItemName(ListOperation op) {
		op.firstOrImplicit.getNameOrDefault.toDecoratedName
	}
	
	def isItemMulti(ListOperation op) {
		cardinalityProvider.isClosureParameterMulti(op)
	}
	
	/**
	 * Does the list operation body expression increase the cardinality? 
	 * 
	 * E.g., 
	 * - from single to list, or from list to list of lists, would return true.
	 * - from single to single, or from list to list, or from list to single, would return false.
	 */
	def isBodyExpressionMulti(ListOperation op) {
		cardinalityProvider.isMulti(op.body, true)
	}
	
	def String getBodyRawType(ListOperation op) {
		typeProvider.getRType(op.body).name.toJavaType
	}
	
	def String getOutputType(ListOperation op) {
		'''«IF funcExt.needsBuilder(op.body)»? extends «ENDIF»«op.bodyRawType»'''
	}
	
	def isPreviousOperationMulti(ListOperation op) {
		cardinalityProvider.isMulti(op.receiver)
	}

	/**
	 * List MAP/FILTER operations can handle a list of lists, however it cannot be handled anywhere else (e.g. a list of list cannot be assigned to a func output or alias)
	 */
	def boolean isOutputListOfLists(ListOperation op) {
		if (op.operationKind == ListOperationKind.FLATTEN) {
			false
		}
		else if (op.operationKind == ListOperationKind.MAP) {
			!op.isItemMulti && op.body !== null && op.isBodyExpressionMulti && op.isPreviousOperationMulti
		} 
		else {
			val previousListOp = op.previousListOperation
			previousListOp !== null && previousListOp.isOutputListOfLists
		}
	}

	/**
	 * Nothing handles a list of list of list
	 */
	def boolean isOutputListOfListOfLists(ListOperation op) {
		if (op.operationKind == ListOperationKind.MAP) {
			val previousListOp = op.previousListOperation
			previousListOp !== null && previousListOp.isOutputListOfLists && op.isBodyExpressionMulti
		} 
		else {
			false
		}
	}

	def getPreviousListOperation(ListOperation op) {
		val previousOperation = op.receiver
		if (previousOperation instanceof ListOperation) {
			return previousOperation
		}
		return null
	}
	
	def isOutputMulti(ListOperation op) {
		 cardinalityProvider.isMulti(op)
	}
}
--!strict
--!native
local Package = script
local Packages = Package.Parent


local Vector = require(Packages.Vector)
export type Vector = Vector.Vector
export type Matrix = {
	__index: Matrix,
	_vectors: {[number]: Vector},
	Dimensions: Vector,
	Magnitude: number,
	Type: string,
	new: (...Vector) -> Matrix,
	ToVectors: (self: Matrix) -> {[number]: Vector},
	ToRows: (self: Matrix) -> {[number]: Vector},
	__add: ((self: Matrix, other: Matrix) -> Matrix)
	& ((self: Matrix, other: Vector) -> Matrix)
	& ((self: Matrix, other: number) -> Matrix),
	__sub: ((self: Matrix, other: Matrix) -> Matrix)
	& ((self: Matrix, other: Vector) -> Matrix)
	& ((self: Matrix, other: number) -> Matrix),
	__mul: ((self: Matrix, other: Matrix) -> Matrix)
	& ((self: Matrix, other: Vector) -> Matrix)
	& ((self: Matrix, other: number) -> Matrix),
	__div: ((self: Matrix, other: Matrix) -> Matrix)
	& ((self: Matrix, other: Vector) -> Matrix)
	& ((self: Matrix, other: number) -> Matrix),
	__mod: ((self: Matrix, other: Matrix) -> Matrix)
	& ((self: Matrix, other: Vector) -> Matrix)
	& ((self: Matrix, other: number) -> Matrix),
	__pow: ((self: Matrix, other: Matrix) -> Matrix)
	& ((self: Matrix, other: Vector) -> Matrix)
	& ((self: Matrix, other: number) -> Matrix),
	__eq: ((self: Matrix, other: any?) -> boolean),
	Transpose: (self: Matrix) -> Matrix,
	__tostring: (self: Matrix) -> nil,
	one: (dimensions: Vector) -> Matrix,
	identity: (dimensions: Vector) -> Matrix,
}


--- @class Matrix
--- A N-Dimensional matrix class meant to work with the N-Dimensional Vector class
local Matrix: any = {}

--- @prop Dimensions Vector
--- @within Matrix
--- A 2 dimensional vector describing the length of the vectors in Y and the number of vectors in X.

--- @prop Type string
--- @within Matrix
--- An identifier for the class

--- @prop Magnitude number
--- @within Matrix
--- The sum of all the vector magnitudes.

--- constructs a new matrix from vector parameters
function Matrix.new(...: Vector)
	local self: {[any]: any} = {}

	self._vectors = { ... } :: { [number]: Vector }
	-- print(self._vectors)
	local xDim: number = #self._vectors
	local yDim: number = self._vectors[1].Size

	self.Dimensions = Vector.new(xDim, yDim)

	self.Type = "Matrix"

	self.Magnitude = 0
	for i, vec in ipairs(self._vectors) do
		self.Magnitude += vec.Magnitude
	end

	setmetatable(self, Matrix)

	return self
end

--- Allows for the access of public variables, as well as the indexing of specific vectors within the matrix.
function Matrix:__index(k: any): any?
	if k == "_vectors" then
		error("Don't try to index private variables")
	end
	return rawget(self, k) or rawget(self, "_vectors")[k] or rawget(Matrix, k)
end

--- Similar to vectors you aren't allowed ot change properties after construction, create a new matrix instead.
function Matrix:__newindex(k, v): nil
	error("You can't change values of this vector post-construction")
end

--- returns a list of vectors used to construct the matrix
function Matrix:ToVectors(): { [number]: Vector }
	local vecs = {}
	for i, vec in ipairs(rawget(self, "_vectors")) do
		table.insert(vecs, vec)
	end
	return vecs
end

--- Performs an addition operation on the matrix and another matrix or vector.
function Matrix:__add(vMatVec: Matrix | Vector): Matrix --add
	local sumVectors: { [number]: Vector } = {}
	for i, mVec: Vector in ipairs(rawget(self, "_vectors")) do
		local vType: string = vMatVec.Type
		assert(typeof(vMatVec) == "table")
		local vVecOrVal: Vector | number = vMatVec[i]
		if typeof(vVecOrVal) == "table" and vType == "Matrix" then
			assert(typeof(vVecOrVal) ~= "number")
			assert(getmetatable(vVecOrVal) == Vector)

			local vVec = vVecOrVal
			local sumVec = mVec + vVec

			sumVectors[i] = sumVec
		else
			assert(typeof(vVecOrVal) == "number")
			local val: number = vVecOrVal
			local sumVec = mVec + val
			sumVectors[i] = sumVec
		end
	end
	return Matrix.new(unpack(sumVectors))
end

--- Performs a subtraction operation on the matrix and another matrix or vector.
function Matrix:__sub(vMatVec: Matrix | Vector): Matrix --add
	local difVectors: { [number]: Vector } = {}
	for i, mVec: Vector in ipairs(rawget(self, "_vectors")) do
		local vType: string = vMatVec.Type
		assert(typeof(vMatVec) == "table")
		local vVecOrVal: Vector | number = vMatVec[i]
		if typeof(vVecOrVal) == "table" and vType == "Matrix" then
			assert(typeof(vVecOrVal) ~= "number")
			local vVec: Vector = vVecOrVal
			local difVec: Vector = mVec + vVec
			difVectors[i] = difVec
		else
			assert(typeof(vVecOrVal) == "number")
			local val: number = vVecOrVal
			local difVec: Vector = mVec + val
			difVectors[i] = difVec
		end
	end
	return Matrix.new(unpack(difVectors))
end

--- Performs a multiplication operation on the matrix and another matrix, vector, or number.
function Matrix:__mul(vMatVecNum: Matrix | Vector | number): Matrix --multiply
	local result: Matrix
	if typeof(vMatVecNum) == "table" then
		assert(vMatVecNum.Type == "Matrix" or vMatVecNum.Type == "Vector")
		if vMatVecNum.Type == "Matrix" then
			local vMatrix: Matrix = vMatVecNum

			assert(self.Dimensions[1] == self.Dimensions[2], "Bad square matrix")
			assert(vMatrix.Dimensions == self.Dimensions, "Bad matrix match")

			local product = {}
			local vColumns: { [number]: Vector } = vMatrix:ToVectors()

			for y, row in ipairs(self:ToRows()) do
				local baseWeights = row:ToScalars()
				product[y] = product[y] or {}
				for x, _ in ipairs(baseWeights) do
					local sum = 0
					local vec: Vector = vColumns[x]
					local multWeights = vec:ToScalars()
					for i, bScal in ipairs(baseWeights) do
						sum += bScal * multWeights[i]
					end
					product[y][x] = sum
				end
				product[y] = Vector.new(unpack(product[y]))
			end
			result = Matrix.new(unpack(product)):Transpose()
		elseif vMatVecNum.Type == "Vector" then
			local vVector: Vector = vMatVecNum
			local vScals: { [number]: number } = vVector:GetScalars()
			result = {}
			for i, mVec in ipairs(rawget(self, "_vectors")) do
				local v = vScals[i]
				result[i] = 0
				for j, s in ipairs(mVec:GetScalars()) do
					result[i] += v * s
				end
			end
		end
	elseif typeof(vMatVecNum) == "number" then
		local vNum: number = vMatVecNum
		local vecs = {}
		for i, s in ipairs(rawget(self, "_vectors")) do
			vecs[i] = s * vNum
		end
		result = Matrix.new(unpack(vecs))
	else
		error("Bad value")
	end
	return result
end

--- Performs a division operation on the matrix and another matrix or number.
function Matrix:__div(v: Matrix | number): Matrix --divide
	if typeof(v) == "table" and v.Type == "Matrix" then
		error("I didn't code matrix division")
	elseif typeof(v) == "number" then
		local quotient = {}
		for i, s in ipairs(rawget(self, "_vectors")) do
			quotient[i] = s / v
		end
		return Matrix.new(unpack(quotient))
	else
		error("Bad value")
	end
end

--- Performs an exponential operation on the matrix and another matrix or number.
function Matrix:__pow(v: Matrix | number): Matrix --power
	if typeof(v) == "table" then
		local result = {}
		for i, s in ipairs(rawget(self, "_vectors")) do
			result[i] = s ^ v[i]
		end
		return Matrix.new(unpack(result))
	elseif typeof(v) == "number" then
		local result = {}
		for i, s in ipairs(rawget(self, "_vectors")) do
			result[i] = s ^ v
		end
		return Matrix.new(unpack(result))
	else
		error("Bad value")
	end
end

--- Performs an modulus operation on the matrix and another matrix or number.
function Matrix:__mod(v: Matrix | number): Matrix --mod
	if typeof(v) == "table" then
		local result = {}
		for i, s in ipairs(rawget(self, "_vectors")) do
			result[i] = s % v[i]
		end
		return Matrix.new(unpack(result))
	elseif typeof(v) == "number" then
		local result = {}
		for i, s in ipairs(rawget(self, "_vectors")) do
			result[i] = s % v
		end
		return Matrix.new(unpack(result))
	else
		error("Bad value")
	end
end

--- Determines if another value is a matrix with the same vectors configuration
function Matrix:__eq(v: any): boolean --equal
	if v == false then
		return false
	end
	if typeof(v) == "table" and v.Type == "Matrix" then
		for i, s in ipairs(rawget(self, "_vectors")) do
			if s ~= v[i] then
				return false
			end
		end
		return true
	else
		return false
	end
end

--- Vectors are written as columns within traditional matrix layout. This returns vectors constructed from the rows.
function Matrix:ToRows(): { [number]: Vector }
	local rows: { [number]: { [number]: number } } = {}
	for i, vec in ipairs(rawget(self, "_vectors")) do
		for vI, s in ipairs(vec:ToScalars()) do
			rows[vI] = rows[vI] or {}
			table.insert(rows[vI], s)
		end
	end
	local vecs: { [number]: Vector } = {}
	for i, vec in ipairs(rows) do
		vecs[i] = Vector.new(unpack(vec))
	end
	-- print(rows)
	return vecs
end

--- Rotates the matrix counter clockwise 90 degrees.
function Matrix:Transpose(): Matrix
	local vectors = self:ToRows()
	return Matrix.new(unpack(vectors))
end

--- Converts matrix to string.
function Matrix:__tostring(): string
	local str = ""
	local rows = self:ToRows()
	for i, row in ipairs(rows) do
		local rowStr = ""
		if i ~= 1 then
			rowStr = rowStr .. "\n"
		end
		for j, s in ipairs(row) do
			if j ~= 1 then
				rowStr = rowStr .. "|" .. tostring(s)
			else
				rowStr = tostring(s)
			end
		end
		str = str .. rowStr
	end
	return str
end

--- Creates a matrix with all vector values set to 1
function Matrix.one(dimensions: Vector): Vector
	local vecs = {}
	for i = 1, dimensions[1] do
		table.insert(vecs, Vector.one(dimensions[2]))
	end
	return Vector.new(unpack(vecs))
end

--- Creates a matrix with any cell along the diagonal of the matrix set to 1.
function Matrix.identity(dimensions: Vector): Vector
	local vecs = {}
	for i = 1, dimensions[1] do
		table.insert(vecs, Vector.identity(dimensions[2], i))
	end
	return Vector.new(unpack(vecs))
end

return Matrix :: Matrix
